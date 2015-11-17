require 'autoscaler/sidekiq/queue_system'
require 'autoscaler/binary_scaling_strategy'
require 'autoscaler/delayed_shutdown'
require 'thread'

module Autoscaler
  module Sidekiq
    # Sidekiq server middleware
    # spawns a thread to monitor the sidekiq server for scale-down
    class ThreadServer
      # @param [scaler] scaler object that actually performs scaling operations (e.g. {HerokuPlatformScaler})
      # @param [Strategy,Numeric] timeout strategy object that determines target workers, or a timeout  in seconds to be passed to {DelayedShutdown}+{BinaryScalingStrategy}
      # @param [Array[String]] specified_queues list of queues to monitor to determine if there is work left.  Defaults to all sidekiq queues.
      def initialize(scaler, timeout, specified_queues = nil)
        @scaler = scaler
        @strategy = strategy(timeout)
        @system = QueueSystem.new(specified_queues)
        @mutex = Mutex.new
        @done = false
      end

      # Sidekiq middleware api entry point
      def call(worker, msg, queue, _ = nil)
        yield
      ensure
        active_now!
        wait_for_downscale
      end

      # Start the monitoring thread if it's not running
      def wait_for_downscale
        @thread ||= Thread.new do
          begin
            run
          rescue
            @thread = nil
          end
        end
      end

      # Thread core loop
      # Periodically update the desired number of workers
      # @param [Numeric] interval polling interval, mostly for testing
      def run(interval = 15)
        active_now!

        workers = :unknown

        begin
          sleep(interval)
          target_workers = @strategy.call(@system, idle_time)
          workers = @scaler.workers = target_workers unless workers == target_workers
        end while !@done && workers > 0
        ::Sidekiq::ProcessSet.new.each(&:quiet!)
      end

      # Shut down the thread, pause until complete
      def terminate
        @done = true
        if @thread
          t = @thread
          @thread = nil
          t.value
        end
      end

      private

      def active_now!
        @mutex.synchronize do
          @activity = Time.now
        end
      end

      def idle_time
        @mutex.synchronize do
          Time.now - @activity
        end
      end

      def strategy(timeout)
        if timeout.respond_to?(:call)
          timeout
        else
          DelayedShutdown.new(BinaryScalingStrategy.new, timeout)
        end
      end
    end
  end
end

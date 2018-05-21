require 'autoscaler/sidekiq/queue_system'
require 'autoscaler/binary_scaling_strategy'
require 'autoscaler/delayed_shutdown'
require 'thread'

module Autoscaler
  module Sidekiq
    # Sidekiq server middleware
    # Sidekiq creates a new instance of the middleware for each worker
    # spawns a Monitor thread to monitor the sidekiq server for scale-down
    class ThreadServer
      # @param [scaler] scaler object that actually performs scaling operations (e.g. {HerokuPlatformScaler})
      # @param [Strategy,Numeric] timeout strategy object that determines target workers, or a timeout  in seconds to be passed to {DelayedShutdown}+{BinaryScalingStrategy}
      # @param [Array[String]] specified_queues list of queues to monitor to determine if there is work left.  Defaults to all sidekiq queues.
      def initialize(scaler, timeout, specified_queues = nil)
        @scaler = scaler
        @strategy = strategy(timeout)
        @system = QueueSystem.new(specified_queues)
      end

      # Sidekiq middleware api entry point
      def call(worker, msg, queue, _ = nil)
        yield
      ensure
        monitor.active_now!
        monitor.wait_for_downscale(@scaler, @strategy, @system)
      end

      private

      def strategy(timeout)
        if timeout.respond_to?(:call)
          timeout
        else
          DelayedShutdown.new(strategy: BinaryScalingStrategy.new, timeout: timeout)
        end
      end

      # Manages the single thread that watches for scaledown
      # Singleton (see bottom) but instanceable for testing
      class Monitor
        def initialize
          @mutex = Mutex.new
          @done = false
        end

        # Start the monitoring thread if it's not running
        # @param [scaler] scaler object that actually performs scaling operations (e.g. {HerokuPlatformScaler})
        # @param [Strategy] strategy object that determines target workers
        # @param [QueueSystem] system queue system that determines which sidekiq queues are watched
        def wait_for_downscale(scaler, strategy, system)
          @thread ||= Thread.new do
            begin
              run(scaler, strategy, system)
            rescue
              @thread = nil
            end
          end
        end

        # Thread core loop
        # Periodically update the desired number of workers
        # @param [scaler] scaler object that actually performs scaling operations (e.g. {HerokuPlatformScaler})
        # @param [Strategy] strategy object that determines target workers
        # @param [QueueSystem] system queue system that determines which sidekiq queues are watched
        # @param [Numeric] interval polling interval, mostly for testing
        def run(scaler, strategy, system, interval = 15)
          active_now!

          workers = :unknown

          begin
            sleep(interval)
            target_workers = strategy.call(system, idle_time)
            workers = scaler.workers = target_workers unless workers == target_workers
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

        # Record last active time
        def active_now!
          @mutex.synchronize do
            @activity = Time.now
          end
        end

        private

        def idle_time
          @mutex.synchronize do
            Time.now - @activity
          end
        end
      end

      Singleton = Monitor.new

      def monitor
        Singleton
      end

      private_constant :Monitor
      private_constant :Singleton
    end
  end
end

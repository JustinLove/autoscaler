require 'celluloid'

module Autoscaler
  module Sidekiq
    # Actor to monitor the sidekiq server for scale-down
    class CelluloidMonitor
      include Celluloid

      # @param [scaler] scaler object that actually performs scaling operations (e.g. {HerokuScaler})
      # @param [Strategy] strategy object that decides the target number of workers (e.g. {BinaryScalingStrategy})
      # @param [System] system interface to the queuing system for use by the strategy
      def initialize(scaler, strategy, system)
        @scaler = scaler
        @strategy = strategy
        @system = system
        @running = false
      end

      # Periodically update the desired number of workers
      # @param [Numeric] interval polling interval, mostly for testing
      def wait_for_downscale(interval = 15)
        once do
          active_now!

          workers = :unknown

          begin
            sleep(interval)
            target_workers = @strategy.call(@system, idle_time)
            workers = @scaler.workers = target_workers unless workers == target_workers
          end while workers > 0
          ::Sidekiq::ProcessSet.new.each(&:quiet!)
        end
      end

      # Notify the monitor that a job is starting
      def starting_job
      end

      # Notify the monitor that a job has finished
      def finished_job
        active_now!
        async.wait_for_downscale
      end

      private

      def active_now!
        @activity = Time.now
      end

      def idle_time
        Time.now - @activity
      end

      def once
        return if @running

        begin
          @running = true
          yield
        ensure
          @running = false
        end
      end
    end
  end
end

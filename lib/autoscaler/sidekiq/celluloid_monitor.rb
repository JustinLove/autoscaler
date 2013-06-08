require 'celluloid'

module Autoscaler
  module Sidekiq
    # Actor to monitor the sidekiq server for scale-down
    class CelluloidMonitor
      include Celluloid

      # @param [scaler] scaler object that actually performs scaling operations (e.g. {HerokuScaler})
      # @param [Numeric] timeout number of seconds to wait before shutdown
      # @param [System] system interface to the queuing system that provides `pending_work?`
      def initialize(scaler, timeout, system)
        @scaler = scaler
        @timeout = timeout
        @poll = [timeout/4.0, 0.5].max
        @system = system
        @running = false
      end

      # Mostly sleep until there has been no activity for the timeout
      def wait_for_downscale
        once do
          active_now!

          while active? || time_left?
            sleep(@poll)
            update_activity
          end

          @scaler.workers = 0
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
      attr_reader :system

      def active?
        system.queued > 0 || system.scheduled > 0 || system.retrying > 0 || system.workers > 0
      end

      def update_activity
        active_now! if active?
      end

      def active_now!
        @activity = Time.now
      end

      def time_left?
        (Time.now - @activity) < @timeout
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

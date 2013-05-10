require 'celluloid'

module Autoscaler
  module Sidekiq
    # Actor to monitor the sidekiq server for scale-down
    class CelluloidMonitor
      include Celluloid

      def self.start!(*args)
        unless Celluloid::Actor[:autoscaler_monitor]
          supervise_as(:autoscaler_monitor, *args).actors.first.async.wait_for_downscale
        end
      end

      # @param [scaler] scaler object that actually performs scaling operations (e.g. {HerokuScaler})
      # @param [Numeric] timeout number of seconds to wait before shutdown
      # @param [System] system interface to the queuing system that provides `pending_work?`
      def initialize(scaler, timeout, system)
        @scaler = scaler
        @timeout = timeout
        @poll = [timeout/4.0, 0.5].max
        @system = system
      end

      # Mostly sleep until there has been no activity for the timeout
      def wait_for_downscale
        active_now!

        while active? || time_left?
          sleep(@poll)
          update_activity
        end

        @scaler.workers = 0
      end

      private
      attr_reader :system

      def active?
        system.pending_work? || system.working?
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
    end
  end
end

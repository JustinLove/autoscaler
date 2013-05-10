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
        @poll = [timeout/4.0, 0.5].min
        @system = system
      end

      # Mostly sleep until there has been no activity for the timeout
      def wait_for_downscale
        while pending_work? || working?
          sleep(@poll)
        end
        @scaler.workers = 0
      end

      private
      attr_reader :system

      def pending_work?
        system.pending_work?
      end

      def working?
        system.working?
      end
    end
  end
end

require 'autoscaler/sidekiq/activity'
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
        @activity = Activity.new(timeout)
        @system = system
      end

      # Mostly sleep until there has been no activity for the timeout
      def wait_for_downscale
        working!
        while pending_work? || working?
          sleep(@poll)
        end
        @scaler.workers = 0
      end

      private
      attr_reader :system
      attr_reader :activity

      def pending_work?
        system.pending_work?
      end

      def working?
        !activity.idle?(system.queue_names)
      end

      def working!
        activity.working!(system.queue_names.first)
      end
    end
  end
end

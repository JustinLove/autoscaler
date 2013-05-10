require 'autoscaler/sidekiq/queue_system'
require 'autoscaler/sidekiq/activity'
require 'celluloid'

module Autoscaler
  module Sidekiq
    # Actor to monitor the sidekiq server for scale-down
    class CelluloidMonitor
      include Celluloid

      # @param [scaler] scaler object that actually performs scaling operations (e.g. {HerokuScaler})
      # @param [Numeric] timeout number of seconds to wait before shutdown
      # @param [Array[String]] specified_queues list of queues to monitor to determine if there is work left.  Defaults to all sidekiq queues.
      def initialize(scaler, timeout, specified_queues = nil)
        @scaler = scaler
        @poll = [timeout/4.0, 0.5].min
        @activity = Activity.new(timeout)
        @system = QueueSystem.new(specified_queues)
        @activity.working!(@system.queue_names.first)
      end

      # Mostly sleep until
      def wait_for_downscale
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
    end
  end
end

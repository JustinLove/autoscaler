require 'autoscaler/sidekiq/queue_system'
require 'autoscaler/sidekiq/activity'

module Autoscaler
  module Sidekiq
    # Sidekiq server middleware
    # Performs scale-down when the queue is empty
    class Server
      # @param [scaler] scaler object that actually performs scaling operations (e.g. {HerokuScaler})
      # @param [Numeric] timeout number of seconds to wait before shutdown
      # @param [Array[String]] specified_queues list of queues to monitor to determine if there is work left.  Defaults to all sidekiq queues.
      def initialize(scaler, timeout, specified_queues = nil)
        @scaler = scaler
        @activity = Activity.new(timeout)
        @system = QueueSystem.new(specified_queues)
      end

      # Sidekiq middleware api entry point
      def call(worker, msg, queue)
        working!(queue)
        yield
      ensure
        working!(queue)
        wait_for_task_or_scale
      end

      private
      def wait_for_task_or_scale
        loop do
          return if pending_work?
          return @scaler.workers = 0 if idle?
          sleep(0.5)
        end
      end

      attr_reader :system
      attr_reader :activity

      def pending_work?
        system.pending_work?
      end

      def working!(queue)
        activity.working!(queue)
      end

      def idle?
        activity.idle?(system.queue_names)
      end
    end
  end
end

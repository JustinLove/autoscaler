require 'autoscaler/sidekiq/queue_system'
require 'autoscaler/sidekiq/activity'

module Autoscaler
  module Sidekiq
    # Sidekiq server middleware
    # Performs scale-down when the queue is empty
    class SleepWaitServer
      # @param [scaler] scaler object that actually performs scaling operations (e.g. {HerokuPlatformScaler})
      # @param [Numeric] timeout number of seconds to wait before shutdown
      # @param [Array[String]] specified_queues list of queues to monitor to determine if there is work left.  Defaults to all sidekiq queues.
      def initialize(scaler, timeout, specified_queues = nil)
        @scaler  = scaler
        @timeout = timeout
        @system  = QueueSystem.new(specified_queues)
      end

      # Sidekiq middleware api entry point
      def call(worker, msg, queue, redis = ::Sidekiq.method(:redis))
        working!(queue, redis)
        yield
      ensure
        working!(queue, redis)
        wait_for_task_or_scale(redis)
      end

      private
      def wait_for_task_or_scale(redis)
        loop do
          return if pending_work?
          return @scaler.workers = 0 if idle?(redis)
          sleep(0.5)
        end
      end

      attr_reader :system

      def pending_work?
        system.any_work?
      end

      def working!(queue, redis)
        Activity.new(@timeout, redis).working!(queue)
      end

      def idle?(redis)
        Activity.new(@timeout, redis).idle?(system.queue_names)
      end
    end
  end
end

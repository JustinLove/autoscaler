require 'autoscaler/sidekiq/queue_system'

module Autoscaler
  module Sidekiq
    # Sidekiq server middleware
    # Performs autoscaling based on jobs capacity
    class AutoscalerServer
      # @param [scaler] scaler object that actually performs scaling operations (e.g. {HerokuPlatformScaler})
      # @param [Numeric] capacity number of jobs to scale
      # @param [Array[String]] specified_queues list of queues to monitor to determine if there is work left.  Defaults to all sidekiq queues.
      def initialize(scaler, capacity = 10, specified_queues = nil)
        @scaler = scaler
        @capacity = capacity
        @system = QueueSystem.new(specified_queues)
      end

      # Sidekiq middleware api entry point
      def call(worker, msg, queue, _ = nil)
        yield
      ensure
        begin
          p "@@@@@@@ AutoscalerServer |#{queue}| #{@system.total_work}"
          workers_count = @system.any_work? ? ((@system.total_work - 1) / @capacity) + 1 : 0
          @scaler.workers = workers_count
        rescue => exception
          puts exception
          puts exception.backtrace
        end
      end

    end
  end
end

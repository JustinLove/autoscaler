require 'sidekiq'

module Autoscaler
  # namespace module for Sidekiq middlewares
  module Sidekiq
    # Sidekiq client middleware
    # Performs scale-up when items are queued and there are no workers running
    class Client
      # @param [Hash] scalers map of queue(String) => scaler (e.g. {HerokuScaler}).
      #   Which scaler to use for each sidekiq queue
      def initialize(scalers)
        @scalers = scalers
      end

      # Sidekiq middleware api method
      def call(worker_class, item, queue)
        @scalers[queue] && @scalers[queue].workers = 1
        yield
      end
    end

    # Sidekiq server middleware
    # Performs scale-down when the queue is empty
    class Server
      # @param [scaler] scaler object that actually performs scaling operations (e.g. {HerokuScaler})
      # @param [Numeric] timeout number of seconds to wait before shutdown
      # @param [Array[String]] specified_queues list of queues to monitor to determine if there is work left.  Defaults to all sidekiq queues.
      def initialize(scaler, timeout, specified_queues = nil)
        @scaler = scaler
        @timeout = timeout
        @specified_queues = specified_queues
      end

      # Sidekiq middleware api entry point
      def call(worker, msg, queue)
        working!
        yield
      ensure
        working!
        wait_for_task_or_scale
      end

      private
      def all_queues
        ::Sidekiq::Stats.new.queues
      end

      def queued_work?
        queues = all_queues
        (@specified_queues || queues.keys).any? {|name| queues[name] > 0}
      end

      def scheduled_work?
        ::Sidekiq::ScheduledSet.new.size > 0
      end

      def retry_work?
        ::Sidekiq::RetrySet.new.size > 0
      end

      def pending_work?
        queued_work? || scheduled_work? || retry_work?
      end

      def wait_for_task_or_scale
        loop do
          return if pending_work?
          return @scaler.workers = 0 if idle?
          sleep(0.5)
        end
      end

      def working!
        ::Sidekiq.redis {|c| c.set('background_activity', Time.now)}
      end

      def idle_time
        ::Sidekiq.redis {|c|
          t = c.get('background_activity')
          return 0 unless t
          Time.now - Time.parse(t)
        }
      end

      def idle?
        idle_time > @timeout
      end
    end
  end
end

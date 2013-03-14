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
        working!(queue)
        yield
      ensure
        working!(queue)
        wait_for_task_or_scale
      end

      private
      def refresh_sidekiq_queues!
        @sidekiq_queues = ::Sidekiq::Stats.new.queues
      end

      attr_reader :sidekiq_queues

      def queue_names
        (@specified_queues || sidekiq_queues.keys)
      end

      def queued_work?
        queue_names.any? {|name| sidekiq_queues[name].to_i > 0 }
      end

      def scheduled_work?
        empty_sorted_set?("schedule")
      end

      def retry_work?
        empty_sorted_set?("retry")
      end

      def empty_sorted_set?(sorted_set)
        ss = ::Sidekiq::SortedSet.new(sorted_set)
        ss.any? { |job| queue_names.include?(job.queue) }
      end

      def pending_work?
        refresh_sidekiq_queues!
        queued_work? || scheduled_work? || retry_work?
      end

      def wait_for_task_or_scale
        loop do
          return if pending_work?
          return @scaler.workers = 0 if idle?
          sleep(0.5)
        end
      end

      def working!(queue)
        active_at queue, Time.now
      end

      # test support
      def idle!(queue)
        active_at queue, Time.now - @timeout*2
      end

      def idle_time
        t = last_activity
        return 0 unless t
        Time.now - Time.parse(t)
      end

      def idle?
        idle_time > @timeout
      end

      def last_activity
        ::Sidekiq.redis {|c|
          queue_names.map {|q| c.get('background_activity:'+q)}.compact.max
        }
      end

      def active_at(queue, time)
        ::Sidekiq.redis {|c| c.set('background_activity:'+queue, time)}
      end
    end
  end
end

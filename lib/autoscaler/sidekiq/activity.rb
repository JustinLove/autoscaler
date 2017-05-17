require 'sidekiq'

module Autoscaler
  module Sidekiq
    # Tracks activity timeouts using Sidekiq's redis connection
    class Activity
      # @param [Numeric] timeout number of seconds to wait before shutdown
      def initialize(timeout, redis = ::Sidekiq.method(:redis))
        @timeout = timeout
        @redis   = redis
      end

      # Record that a queue has activity
      # @param [String] queue
      def working!(queue)
        active_at queue, Time.now
      end

      # Record that a queue is idle and timed out - mostly for test support
      # @param [String] queue
      def idle!(queue)
        active_at queue, Time.now - timeout*2
      end

      # Have the watched queues timed out?
      # @param [Array[String]] queues list of queues to monitor to determine if there is work left
      # @return [boolean]
      def idle?(queues)
        idle_time(queues) > timeout
      end

      private
      attr_reader :timeout

      def idle_time(queues)
        t = last_activity(queues)
        return 0 unless t
        Time.now - Time.parse(t)
      end

      def last_activity(queues)
        redis {|c|
          queues.map {|q| c.get('background_activity:'+q)}.compact.max
        }
      end

      def active_at(queue, time)
        redis {|c| c.set('background_activity:'+queue, time)}
      end

      def redis(&block)
        # Redis implements call for something else
        if @redis.respond_to?(:call) && !@redis.kind_of?(Redis)
          @redis.call(&block)
        elsif @redis.respond_to?(:with)
          @redis.with(&block)
        else
          block.call(@redis)
        end
      end
    end
  end
end

module Autoscaler
  # Implements a cache for the number of heroku works currently up
  # This permits some web/worker communication, which makes longer timeouts practical.
  class CounterCacheRedis
    # @param [Proc, ConnectionPool, Redis client] redis redis interface
    #   Proc: e.g. Sidekiq.method(:redis)
    #   ConnectionPool: e.g. what you pass to Sidekiq.redis=
    #   Redis client: e.g. Redis.connect
    # @param [Numeric] timeout number of seconds to allow before expiration
    def initialize(redis, timeout = 5 * 60)
      @redis = redis
      @timeout = timeout
    end

    # @param [Numeric] value new counter value
    def counter=(value)
      redis {|c| c.setex('autoscaler:workers', @timeout, value)}
    end

    # Raised when no block is provided to #counter
    class Expired < ArgumentError; end

    # Current value.  Uses the Hash#fetch api - pass a block to use in place of expired values or it will raise an exception.
    def counter
      value = redis {|c| c.get('autoscaler:workers')}
      return value.to_i if value
      return yield if block_given?
      raise Expired
    end

    private
    attr_reader :timeout

    def redis(&block)
      if @redis.respond_to?(:call)
        @redis.call(&block)
      elsif @redis.respond_to?(:with)
        @redis.with(&block)
      else
        block.call(@redis)
      end
    end
  end
end

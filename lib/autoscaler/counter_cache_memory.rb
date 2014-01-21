module Autoscaler
  # Implements a cache for the number of heroku works currently up
  # Values are stored for short periods in the object
  class CounterCacheMemory
    # @param [Numeric] timeout number of seconds to allow before expiration
    def initialize(timeout = 5)
      @timeout = timeout
      @counter = 0
      @valid_until = Time.now - 1
    end

    # @param [Numeric] value new counter value
    def counter=(value)
      @valid_until = Time.now + @timeout
      @counter = value
    end

    # Raised when no block is provided to #counter
    class Expired < ArgumentError; end

    # Current value.  Uses the Hash#fetch api - pass a block to use in place of expired values or it will raise an exception.
    def counter
      return @counter if valid?
      return yield if block_given?
      raise Expired
    end

    private
    attr_reader :timeout

    def valid?
      Time.now < @valid_until
    end
  end
end

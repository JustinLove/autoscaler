module Autoscaler
  # - Strategy wrapper to ignore scheduled and retrying queues. Usage:
  #  ``new_strategy = IgnoreScheduledAndRetrying.new(my_old_strategy)``
  class IgnoreScheduledAndRetrying
    def initialize(strategy)
      @strategy = strategy
    end

    # @param [QueueSystem] system interface to the queuing system
    # @param [Numeric] event_idle_time number of seconds since a job related event
    # @return [Integer] target number of workers
    def call(system, event_idle_time)
      system.define_singleton_method(:scheduled) { 0 }
      system.define_singleton_method(:retrying)  { 0 }
      @strategy.call(system, event_idle_time)
    end
  end
end

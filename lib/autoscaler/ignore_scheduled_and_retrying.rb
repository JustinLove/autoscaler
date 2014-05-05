module Autoscaler
  class IgnoreScheduledAndRetrying
    def initialize(strategy)
      @strategy = strategy
    end

    def call(system, event_idle_time)
      system.define_singleton_method(:scheduled) { 0 }
      system.define_singleton_method(:retrying)  { 0 }
      @strategy.call(system, event_idle_time)
    end
  end
end

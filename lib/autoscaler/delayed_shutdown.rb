module Autoscaler
  # This is a sort of middleware that keeps the last worker up for a minimum amount of time
  class DelayedShutdown
    # @param [ScalingStrategy] strategy object that makes most decisions
    # @param [Numeric] timeout number of seconds to stay up after base strategy says zero
    def initialize(strategy:, timeout:)
      @strategy = strategy
      @timeout = timeout
      active_now!
    end

    # @param [QueueSystem] system interface to the queuing system
    # @param [Numeric] event_idle_time number of seconds since a job related event
    # @return [Integer] target number of workers
    def call(system, event_idle_time)
      target_workers = strategy.call(system, event_idle_time)
      if target_workers > 0
        active_now!
        target_workers
      elsif time_left?(event_idle_time)
        1
      else
        0
      end
    end

    private

    attr_reader :strategy
    attr_reader :timeout

    def active_now!
      @activity = Time.now
    end

    def level_idle_time
      Time.now - @activity
    end

    def time_left?(event_idle_time)
      [event_idle_time, level_idle_time].min < timeout
    end
  end
end

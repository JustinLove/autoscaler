module Autoscaler
  # Strategies determine the target number of workers
  # The default strategy has a single worker when there is anything, or shuts it down.
  class ZeroOneScalingStrategy
    def initialize(timeout)
      @timeout = timeout
      active_now!
    end

    attr_reader :timeout

    # @param [QueueSystem] system interface to the queuing system
    # @param [Numeric] event_idle_time number of seconds since a job related event
    # @return [Integer] target number of workers
    def call(system, event_idle_time)
      if active?(system)
        active_now!
        1
      elsif time_left?(event_idle_time)
        1
      else
        0
      end
    end

    private
    def active?(system)
      system.queued > 0 || system.scheduled > 0 || system.retrying > 0 || system.workers > 0
    end

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

module Autoscaler
  # Strategies determine the target number of workers
  # The default strategy has a single worker when there is anything, or shuts it down.
  class AutoScalingStrategy
    #@param [integer] active_workers number of workers when in the active state.
    def initialize(jobs_limit = 100)
      @jobs_limit = jobs_limit
    end

    # @param [QueueSystem] system interface to the queuing system
    # @param [Numeric] event_idle_time number of seconds since a job related event
    # @return [Integer] target number of workers
    def call(system, event_idle_time)
      if active?(system)
        ((jobs_count(system) - 1) / @jobs_limit) + 1
      else
        0
      end
    end

    private
    def active?(system)
      system.any_work?
    end

    def jobs_count(system)
      system.total_work
    end
  end
end


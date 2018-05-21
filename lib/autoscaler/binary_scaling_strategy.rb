module Autoscaler
  # Strategies determine the target number of workers
  # The default strategy has a single worker when there is anything, or shuts it down.
  class BinaryScalingStrategy
    #@param [integer] active_workers number of workers when in the active state.
    def initialize(active_workers: 1)
      @active_workers = active_workers
    end

    # @param [QueueSystem] system interface to the queuing system
    # @param [Numeric] event_idle_time number of seconds since a job related event
    # @return [Integer] target number of workers
    def call(system, event_idle_time)
      if active?(system)
        @active_workers
      else
        0
      end
    end

    private
    def active?(system)
      system.any_work?
    end
  end
end

module Autoscaler
  # Strategies determine the target number of workers
  # This strategy sets the worker processess in order to have one Sidekiq actor per queued job.  Please note that there is no upper limit.
  class LinearScalingStrategy
    #@param [integer] active_workers number of workers when in the active state.
    def initialize(workers = 1, worker_capacity = 25)
      @workers         = workers
      @worker_capacity = worker_capacity
    end

    # @param [QueueSystem] system interface to the queuing system
    # @param [Numeric] event_idle_time number of seconds since a job related event
    # @return [Integer] target number of workers
    def call(system, event_idle_time)
      total_capacity   = (@workers * @worker_capacity).to_f
      percent_capacity = total_work(system) / total_capacity

      ideal_scale = (percent_capacity * @workers).ceil
      max_scale   = @workers

      target = [ideal_scale, system.workers].max
      return [max_scale, target].min
    end

    private
    def total_work(system)
      system.queued + system.scheduled + system.retrying
    end
  end
end

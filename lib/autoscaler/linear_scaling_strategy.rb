module Autoscaler
  # Strategies determine the target number of workers
  # This strategy sets the number of workers to be proportional to the number of enqueued jobs.
  class LinearScalingStrategy
    #@param [integer] workers maximum number of workers to spin up.
    #@param [integer] worker_capacity the amount of jobs one worker can handle
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

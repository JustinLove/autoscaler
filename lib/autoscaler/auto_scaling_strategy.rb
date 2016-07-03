module Autoscaler
  # Strategies determine the target number of workers
  # This strategy sets the number of workers to be proportional to the number of enqueued jobs.
  class AutoScalingStrategy
    #@param [integer] max_workers     maximum number of workers to spin up.
    #@param [integer] worker_capacity the amount of jobs one worker can handle
    def initialize(max_workers = 1, worker_capacity = 50)
      @max_workers = max_workers
      @worker_capacity = worker_capacity
    end

    # @param [QueueSystem] system interface to the queuing system
    # @param [Numeric] event_idle_time number of seconds since a job related event
    # @return [Integer] target number of workers
    def call(system, event_idle_time)
      initial_workers = system.workers == 0 ? 1 : system.workers
      workers_count = system.any_work? ? ((system.total_work - 1) / @worker_capacity) + 1 : initial_workers

      return [workers_count, @max_workers].min
    end
  end
end

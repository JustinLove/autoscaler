module Autoscaler
  # Strategies determine the target number of workers
  # This strategy sets the number of workers to be proportional to the number of enqueued jobs.
  class LinearScalingStrategy
    #@param [integer] max_workers     maximum number of workers to spin up.
    #@param [integer] worker_capacity the amount of jobs one worker can handle
    #@param [float]   min_factor      minimum work required to scale, as percentage of worker_capacity
    def initialize(max_workers: 1, worker_capacity: 25, min_factor: 0)
      @max_workers             = max_workers # max # of workers we can scale to
      @total_capacity          = (@max_workers * worker_capacity).to_f # total capacity of max workers
      min_capacity             = [0, min_factor].max.to_f * worker_capacity # min capacity required to scale first worker
      @min_capacity_percentage = min_capacity / @total_capacity # min percentage of total capacity
    end

    # @param [QueueSystem] system interface to the queuing system
    # @param [Numeric] event_idle_time number of seconds since a job related event
    # @return [Integer] target number of workers
    def call(system, event_idle_time)
      requested_capacity_percentage = total_work(system) / @total_capacity

      # Scale requested capacity taking into account the minimum required
      scale_factor = (requested_capacity_percentage - @min_capacity_percentage) / (@total_capacity - @min_capacity_percentage)
      scale_factor = 0 if scale_factor.nan? # Handle DIVZERO

      scaled_capacity_percentage = scale_factor * @total_capacity

      ideal_workers = ([0, scaled_capacity_percentage].max * @max_workers).ceil
      min_workers   = [system.workers, ideal_workers].max  # Don't scale down past number of currently engaged workers
      max_workers   = [min_workers,  @max_workers].min     # Don't scale up past number of max workers

      return [min_workers, max_workers].min
    end

    private
    def total_work(system)
      system.total_work
    end
  end
end

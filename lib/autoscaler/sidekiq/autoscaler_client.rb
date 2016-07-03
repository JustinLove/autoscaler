require 'autoscaler/auto_scaling_strategy'
require 'autoscaler/sidekiq/queue_system'

module Autoscaler
  module Sidekiq
    # Sidekiq client middleware
    # Performs scale-up when items are queued and there are no workers running
    class AutoscalerClient
      # @param [Hash] scalers map of queue(String) => scaler (e.g. {HerokuPlatformScaler}).
      #   Which scaler to use for each sidekiq queue
      # @param [ScalingStrategy] strategy object that makes most decisions
      def initialize(scalers, strategy = nil)
        @scalers = scalers
        @strategy = strategy || AutoScalingStrategy.new
      end

      # Sidekiq middleware api method
      def call(worker_class, item, queue, _ = nil)
        result = yield

        scaler = @scalers[queue]
        if scaler
          scaler.workers = @strategy.call(SpecifiedQueueSystem.new([queue]), 0)
        end

        result
      end

      # Check for interrupted or scheduled work on startup.
      # Typically you need to construct your own instance just
      # to call this method, but see add_to_chain.
      # @param [Strategy] strategy object that determines target workers
      # @yieldparam [String] queue mostly for testing
      # @yieldreturn [QueueSystem] mostly for testing
      def set_initial_workers(strategy = nil, &system_factory)
        strategy ||= AutoScalingStrategy.new
        system_factory ||= lambda { |queue| SpecifiedQueueSystem.new([queue]) }
        @scalers.each do |queue, scaler|
          scaler.workers = strategy.call(system_factory.call(queue), 0)
        end
      end

      # Convenience method to avoid having to name the class and parameter
      # twice when calling set_initial_workers
      # @return [Client] an instance of Client for set_initial_workers
      def self.add_to_chain(chain, scalers)
        chain.add self, scalers
        new(scalers)
      end
    end
  end
end

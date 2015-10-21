require 'sidekiq/api'

module Autoscaler
  module Sidekiq
    # Interface to to interrogate the queuing system
    # Includes every queue
    class EntireQueueSystem
      # @return [Integer] number of workers actively engaged
      def workers
        ::Sidekiq::Workers.new.map {|pid, _, _| pid}.uniq.size
        # #size may be out-of-date.
      end

      # @return [Integer] amount work ready to go
      def queued
        sidekiq_queues.values.map(&:to_i).reduce(&:+) || 0
      end

      # @return [Integer] amount of work scheduled for some time in the future
      def scheduled
        ::Sidekiq::ScheduledSet.new.size
      end

      # @return [Integer] amount of work still being retried
      def retrying
        ::Sidekiq::RetrySet.new.size
      end

      # @return [Boolean] if any kind of work still needs to be done
      def any_work?
        queued > 0 || scheduled > 0 || retrying > 0 || workers > 0
      end

      # @return [Integer] total amount of work
      def total_work
        queued + scheduled + retrying + workers
      end

      # @return [Array[String]]
      def queue_names
        sidekiq_queues.keys
      end

      private

      def sidekiq_queues
        ::Sidekiq::Stats.new.queues
      end
    end
  end
end

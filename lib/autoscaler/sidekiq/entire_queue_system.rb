require 'sidekiq/api'

module Autoscaler
  module Sidekiq
    # Interface to to interrogate the queuing system
    # Includes every queue
    class EntireQueueSystem
      # @return [Integer] number of worker actively engaged
      def workers
        ::Sidekiq::Workers.new.size
      end

      # @return [Integer] amount work ready to go
      def queued
        sidekiq_queues.values.map(&:to_i).reduce(&:+) || 0
      end

      # @return [Integer] amount of work scheduled for some time in the future
      def scheduled
        count_sorted_set("schedule")
      end

      # @return [Integer] amount of work still being retried
      def retrying
        count_sorted_set("retry")
      end

      # @return [Array[String]]
      def queue_names
        sidekiq_queues.keys
      end

      private

      def sidekiq_queues
        ::Sidekiq::Stats.new.queues
      end

      def count_sorted_set(sorted_set)
        ::Sidekiq::SortedSet.new(sorted_set).count
      end
    end
  end
end

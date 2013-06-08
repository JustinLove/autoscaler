require 'sidekiq/api'

module Autoscaler
  module Sidekiq
    # Interface to to interrogate the queuing system
    # Includes only the queues provided to the constructor
    class SpecifiedQueueSystem
      # @param [Array[String]] specified_queues list of queues to monitor to determine if there is work left.  Defaults to all sidekiq queues.
      def initialize(specified_queues)
        @queue_names = specified_queues
      end

      # @return [Integer] total work - does not include work currently in progress
      def pending
        queued + scheduled + retrying
      end

      # @return [Integer] amount work ready to go
      def queued
        queue_names.map {|name| sidekiq_queues[name].to_i}.reduce(&:+)
      end

      # @return [Integer] amount of work scheduled for some time in the future
      def scheduled
        count_sorted_set("schedule")
      end

      # @return [Integer] amount of work still being retried
      def retrying
        count_sorted_set("retry")
      end

      # @return [Integer] number of worker actively engaged
      def workers
        ::Sidekiq::Workers.new.count {|name, work|
          queue_names.include?(work['queue'])
        }
      end

      # @return [Array[String]]
      attr_reader :queue_names

      private
      def sidekiq_queues
        ::Sidekiq::Stats.new.queues
      end

      def count_sorted_set(sorted_set)
        ss = ::Sidekiq::SortedSet.new(sorted_set)
        ss.count { |job| queue_names.include?(job.queue) }
      end
    end
  end
end

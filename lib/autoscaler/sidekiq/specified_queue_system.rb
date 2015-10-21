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

      # @return [Integer] number of workers actively engaged
      def workers
        ::Sidekiq::Workers.new.select {|_, _, work|
          queue_names.include?(work['queue'])
        }.map {|pid, _, _| pid}.uniq.size
      end

      # @return [Integer] amount work ready to go
      def queued
        queue_names.map {|name| sidekiq_queues[name].to_i}.reduce(&:+)
      end

      # @return [Integer] amount of work scheduled for some time in the future
      def scheduled
        count_set(::Sidekiq::ScheduledSet.new)
      end

      # @return [Integer] amount of work still being retried
      def retrying
        count_set(::Sidekiq::RetrySet.new)
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
      attr_reader :queue_names

      private
      def sidekiq_queues
        ::Sidekiq::Stats.new.queues
      end

      def count_set(set)
        set.count { |job| queue_names.include?(job.queue) }
      end
    end
  end
end

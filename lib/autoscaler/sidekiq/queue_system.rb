require 'sidekiq'

module Autoscaler
  module Sidekiq
    # Interface to to interrogate the queuing system
    class QueueSystem
      # @param [Array[String]] specified_queues list of queues to monitor to determine if there is work left.  Defaults to all sidekiq queues.
      def initialize(specified_queues = nil)
        @specified_queues = specified_queues
      end

      # @return [boolean] whether there is queued work - does not include work currently in progress
      def pending_work?
        refresh_sidekiq_queues!
        queued_work? || scheduled_work? || retry_work?
      end

      # @return [Array[String]]
      def queue_names
        (@specified_queues || sidekiq_queues.keys)
      end

      private
      def queued_work?
        queue_names.any? {|name| sidekiq_queues[name].to_i > 0 }
      end

      def scheduled_work?
        empty_sorted_set?("schedule")
      end

      def retry_work?
        empty_sorted_set?("retry")
      end

      attr_reader :sidekiq_queues

      def refresh_sidekiq_queues!
        @sidekiq_queues = ::Sidekiq::Stats.new.queues
      end

      def empty_sorted_set?(sorted_set)
        ss = ::Sidekiq::SortedSet.new(sorted_set)
        ss.any? { |job| queue_names.include?(job.queue) }
      end
    end
  end
end

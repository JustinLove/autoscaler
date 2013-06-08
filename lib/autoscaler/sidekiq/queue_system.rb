require 'sidekiq/api'
require 'autoscaler/sidekiq/specified_queue_system'
require 'autoscaler/sidekiq/entire_queue_system'

module Autoscaler
  module Sidekiq
    # Interface to to interrogate the queuing system
    # convenience constructor for SpecifiedQueueSystem and EntireQueueSystem
    module QueueSystem
      # @param [Array[String]] specified_queues list of queues to monitor to determine if there is work left.  Defaults to all sidekiq queues.
      def self.new(specified_queues = nil)
        if specified_queues
          SpecifiedQueueSystem.new(specified_queues)
        else
          EntireQueueSystem.new
        end
      end
    end
  end
end

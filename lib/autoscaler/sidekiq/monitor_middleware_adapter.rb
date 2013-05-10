require 'autoscaler/sidekiq/queue_system'
require 'autoscaler/sidekiq/celluloid_monitor'

module Autoscaler
  module Sidekiq
    # Shim to the existing autoscaler interface - the sole purpose of this middleware to start CelluloidMonitor
    class MonitorMiddlewareAdapter
      # @param [scaler] scaler object that actually performs scaling operations (e.g. {HerokuScaler})
      # @param [Numeric] timeout number of seconds to wait before shutdown
      # @param [Array[String]] specified_queues list of queues to monitor to determine if there is work left.  Defaults to all sidekiq queues.
      def initialize(scaler, timeout, specified_queues = nil)
        system = QueueSystem.new(specified_queues)
        CelluloidMonitor.supervise(scaler, timeout, system)
      end

      # Sidekiq middleware api entry point - noop
      def call(worker, msg, queue)
        yield
      end
    end
  end
end

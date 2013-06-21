require 'autoscaler/sidekiq/queue_system'
require 'autoscaler/sidekiq/celluloid_monitor'
require 'autoscaler/binary_scaling_strategy'
require 'autoscaler/delayed_shutdown'

module Autoscaler
  module Sidekiq
    # Shim to the existing autoscaler interface
    # Starts the monitor and notifies it of job events that may occur while it's sleeping
    class MonitorMiddlewareAdapter
      # @param [scaler] scaler object that actually performs scaling operations (e.g. {HerokuScaler})
      # @param [Strategy,Numeric] timeout strategy object that determines target workers, or a timeout to be passed to {DelayedShutdown}+{BinaryScalingStrategy}
      # @param [Array[String]] specified_queues list of queues to monitor to determine if there is work left.  Defaults to all sidekiq queues.
      def initialize(scaler, timeout, specified_queues = nil)
        unless monitor
          CelluloidMonitor.supervise_as(:autoscaler_monitor,
                                        scaler,
                                        strategy(timeout),
                                        QueueSystem.new(specified_queues))
        end
      end

      # Sidekiq middleware api entry point
      def call(worker, msg, queue)
        monitor.async.starting_job
        yield
      ensure
        monitor.async.finished_job
      end

      private
      def monitor
        Celluloid::Actor[:autoscaler_monitor]
      end

      def strategy(timeout)
        if timeout.respond_to?(:call)
          timeout
        else
          DelayedShutdown.new(BinaryScalingStrategy.new, timeout)
        end
      end
    end
  end
end

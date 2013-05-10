require 'autoscaler/sidekiq/client'
require 'autoscaler/sidekiq/monitor_middleware_adapter'

module Autoscaler
  # namespace module for Sidekiq middlewares
  module Sidekiq
    # Sidekiq server middleware
    # Performs scale-down when the queue is empty
    Server = MonitorMiddlewareAdapter
  end
end

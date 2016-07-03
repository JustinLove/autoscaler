require 'autoscaler/sidekiq/client'
require 'autoscaler/sidekiq/thread_server'
require 'autoscaler/sidekiq/autoscaler_client'
require 'autoscaler/sidekiq/autoscaler_server'

module Autoscaler
  # namespace module for Sidekiq middlewares
  module Sidekiq
    # Sidekiq server middleware
    # Performs scale-down when the queue is empty
    Server = ThreadServer
  end
end

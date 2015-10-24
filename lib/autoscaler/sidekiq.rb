require 'autoscaler/sidekiq/client'
require 'autoscaler/sidekiq/thread_server'

module Autoscaler
  # namespace module for Sidekiq middlewares
  module Sidekiq
    # Sidekiq server middleware
    # Performs scale-down when the queue is empty
    Server = ThreadServer
  end
end

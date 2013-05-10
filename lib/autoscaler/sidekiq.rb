require 'autoscaler/sidekiq/client'
require 'autoscaler/sidekiq/sleep_wait_server'

module Autoscaler
  # namespace module for Sidekiq middlewares
  module Sidekiq
    # Sidekiq server middleware
    # Performs scale-down when the queue is empty
    Server = SleepWaitServer
  end
end

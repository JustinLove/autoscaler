require 'autoscaler/sidekiq/sleep_wait_server'

module Autoscaler
  module Sidekiq
    # Sidekiq server middleware
    # Monitor the sidekiq server for scale-down
    class NonThreadServer < SleepWaitServer

      private
      def wait_for_task_or_scale(redis)
        while idle?(redis) || !pending_work?
          sleep(1)
        end
        @scaler.workers = 0 if last_work?
      end

      def last_work?
        @scaler.workers >= 1 && system.total_work == 1
      end
    end
  end
end

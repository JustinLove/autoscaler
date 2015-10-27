require 'sidekiq'
require 'autoscaler/sidekiq'
require 'autoscaler/heroku_platform_scaler'

# This is setup for a single queue (default) and worker process (worker)

heroku = nil
if ENV['HEROKU_APP']
  heroku = Autoscaler::HerokuPlatformScaler.new
  #heroku.exception_handler = lambda {|exception| MyApp.logger.error(exception)}
end

Sidekiq.configure_client do |config|
  if heroku
    config.client_middleware do |chain|
      chain.add Autoscaler::Sidekiq::Client, 'default' => heroku
    end
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    if heroku
      p "Setting up auto-scaledown"
      chain.add(Autoscaler::Sidekiq::Server, heroku, 60) # 60 second timeout
    else
      p "Not scaleable"
    end
  end
end

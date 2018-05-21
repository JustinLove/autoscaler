require 'sidekiq'
require 'autoscaler/sidekiq'
require 'autoscaler/heroku_platform_scaler'

# This setup is for multiple queues, where each queue has a dedicated process type

heroku = nil
if ENV['AUTOSCALER_HEROKU_APP']
  heroku = {}
  scaleable = %w[default import] - (ENV['ALWAYS'] || '').split(' ')
  scaleable.each do |queue|
    # We are using the convention that worker process type is the
    # same as the queue name
    heroku[queue] = Autoscaler::HerokuPlatformScaler.new(
      type: queue,
      token: ENV['AUTOSCALER_HEROKU_ACCESS_TOKEN'],
      app: ENV['AUTOSCALER_HEROKU_APP'])
  end
end

Sidekiq.configure_client do |config|
  if heroku
    config.client_middleware do |chain|
      chain.add Autoscaler::Sidekiq::Client, heroku
    end
  end
end

# define AUTOSCALER_HEROKU_PROCESS in the Procfile:
#
#    default: env AUTOSCALER_HEROKU_PROCESS=default bundle exec sidekiq -r ./background/boot.rb
#    import:  env AUTOSCALER_HEROKU_PROCESS=import bundle exec sidekiq -q import -c 1 -r ./background/boot.rb

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    if heroku && ENV['AUTOSCALER_HEROKU_PROCESS'] && heroku[ENV['AUTOSCALER_HEROKU_PROCESS']]
      p "Setting up auto-scaledown"
      chain.add(Autoscaler::Sidekiq::Server, heroku[ENV['AUTOSCALER_HEROKU_PROCESS']], 60, [ENV['AUTOSCALER_HEROKU_PROCESS']]) # 60 second timeout
    else
      p "Not scaleable"
    end
  end
end

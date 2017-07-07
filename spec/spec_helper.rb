require 'rspec/its'
require 'sidekiq'
REDIS = Sidekiq::RedisConnection.create(:url => 'redis://localhost:9736')

RSpec.configure do |config|
  config.mock_with :rspec

  config.filter_run_excluding :api1 => true unless ENV['HEROKU_API_KEY']
  config.filter_run_excluding :platform_api => true unless ENV['AUTOSCALER_HEROKU_ACCESS_TOKEN'] || ENV['HEROKU_ACCESS_TOKEN']
end

class TestScaler
  attr_accessor :workers

  def initialize(n = 0)
    self.workers = n
  end
end

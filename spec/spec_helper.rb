RSpec.configure do |config|
  config.mock_with :rspec

  config.filter_run_excluding :online => true unless ENV['HEROKU_APP']
end

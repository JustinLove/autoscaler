require 'spec_helper'
require 'autoscaler/heroku_scaler'

describe Autoscaler::HerokuScaler, :online => true do
  let(:cut) {Autoscaler::HerokuScaler}
  let(:client) {cut.new}
  subject {client}

  describe 'scaled' do
    around do |example|
      client.workers = 1
      example.yield
      client.workers = 0
    end

    its(:workers) {should == 1}
  end

  describe 'scaled to max workers' do
    Autoscaler.configure do |config|
      config.max_workers = 2
    end
    
    around do |example|
      client.workers = 3
      example.yield
      client.workers = 0
    end

    its(:workers) {should == 2}
  end
end

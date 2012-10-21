require 'spec_helper'
require 'autoscaler/heroku_scaler'

describe Autoscaler::HerokuScaler, :online => true do
  let(:cut) {Autoscaler::HerokuScaler}
  let(:client) {cut.new}
  subject {client}

  its(:workers) {should == 0}

  describe 'scaled' do
    around do |example|
      client.workers = 1
      example.yield
      client.workers = 0
    end

    its(:workers) {should == 1}
  end
end

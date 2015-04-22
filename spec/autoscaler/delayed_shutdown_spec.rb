require 'spec_helper'
require 'test_system'
require 'autoscaler/delayed_shutdown'

describe Autoscaler::DelayedShutdown do
  let(:cut) {Autoscaler::DelayedShutdown}

  it "returns normal values" do
    strategy = cut.new(lambda{|s,t| 2}, 0)
    expect(strategy.call(nil, 1)).to eq 2
  end

  it "delays zeros" do
    strategy = cut.new(lambda{|s,t| 0}, 60)
    expect(strategy.call(nil, 1)).to eq 1
  end

  it "eventually returns zero" do
    strategy = cut.new(lambda{|s,t| 0}, 60)
    allow(strategy).to receive(:level_idle_time).and_return(61)
    expect(strategy.call(nil, 61)).to eq 0
  end
end

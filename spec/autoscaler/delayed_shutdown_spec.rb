require 'spec_helper'
require 'test_system'
require 'autoscaler/delayed_shutdown'

describe Autoscaler::DelayedShutdown do
  let(:cut) {Autoscaler::DelayedShutdown}

  it "returns normal values" do
    strategy = cut.new(lambda{|s,t| 2}, 0)
    strategy.call(nil, 1).should == 2
  end

  it "delays zeros" do
    strategy = cut.new(lambda{|s,t| 0}, 60)
    strategy.call(nil, 1).should == 1
  end

  it "eventually returns zero" do
    strategy = cut.new(lambda{|s,t| 0}, 60)
    strategy.stub(:level_idle_time).and_return(61)
    strategy.call(nil, 61).should == 0
  end
end

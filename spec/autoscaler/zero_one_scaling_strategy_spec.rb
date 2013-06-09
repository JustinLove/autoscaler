require 'spec_helper'
require 'test_system'
require 'autoscaler/zero_one_scaling_strategy'

describe Autoscaler::ZeroOneScalingStrategy do
  let(:cut) {Autoscaler::ZeroOneScalingStrategy}

  it "scales with no work" do
    system = TestSystem.new(0)
    strategy = cut.new
    strategy.call(system, 1).should == 0
  end

  it "does not scale with pending work" do
    system = TestSystem.new(1)
    strategy = cut.new
    strategy.call(system, 1).should == 1
  end
end

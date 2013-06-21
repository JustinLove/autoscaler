require 'spec_helper'
require 'test_system'
require 'autoscaler/binary_scaling_strategy'

describe Autoscaler::BinaryScalingStrategy do
  let(:cut) {Autoscaler::BinaryScalingStrategy}

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

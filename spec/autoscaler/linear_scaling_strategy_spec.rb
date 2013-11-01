require 'spec_helper'
require 'test_system'
require 'autoscaler/linear_scaling_strategy'

describe Autoscaler::LinearScalingStrategy do
  let(:cut) {Autoscaler::LinearScalingStrategy}

  it "deactivates with no work" do
    system = TestSystem.new(0)
    strategy = cut.new(1)
    strategy.call(system, 1).should == 0
  end

  it "activates with some work" do
    system = TestSystem.new(1)
    strategy = cut.new(1)
    strategy.call(system, 1).should be > 0
  end

  it "minimally scales with minimal work" do
    system = TestSystem.new(1)
    strategy = cut.new(2, 2)
    strategy.call(system, 1).should == 1
  end

  it "maximally scales with too much work" do
    system = TestSystem.new(5)
    strategy = cut.new(2, 2)
    strategy.call(system, 1).should == 2
  end

  it "proportionally scales with some work" do
    system = TestSystem.new(5)
    strategy = cut.new(5, 2)
    strategy.call(system, 1).should == 3
  end
end

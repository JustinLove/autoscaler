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

  it "doesn't scale unless minimum is met" do
    system = TestSystem.new(2)
    strategy = cut.new(10, 4, 0.5)
    strategy.call(system, 1).should == 0
  end

  it "scales proprotionally with a minimum" do
    system = TestSystem.new(3)
    strategy = cut.new(10, 4, 0.5)
    strategy.call(system, 1).should == 1
  end

  it "scales maximally with a minimum" do
    system = TestSystem.new(25)
    strategy = cut.new(5, 4, 0.5)
    strategy.call(system, 1).should == 5
  end

  it "scales proportionally with a minimum > 1" do
    system = TestSystem.new(12)
    strategy = cut.new(5, 4, 2)
    strategy.call(system, 1).should == 2
  end

  it "scales maximally with a minimum factor > 1" do
    system = TestSystem.new(30)
    strategy = cut.new(5, 4, 2)
    strategy.call(system, 1).should == 5
  end

  xit "doesn't scale down engaged workers" do
    system = TestSystem.new(0, 2)
    strategy = cut.new(5, 4)
    strategy.call(system, 1).should == 2
  end

  xit "doesn't scale above max workers even if engaged workers is greater" do
    system = TestSystem.new(40, 6)
    strategy = cut.new(5, 4)
    strategy.call(system, 1).should == 5
  end
end

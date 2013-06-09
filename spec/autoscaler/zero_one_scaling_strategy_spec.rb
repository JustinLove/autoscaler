require 'spec_helper'
require 'test_system'
require 'autoscaler/zero_one_scaling_strategy'
require 'timeout'

describe Autoscaler::ZeroOneScalingStrategy do
  let(:cut) {Autoscaler::ZeroOneScalingStrategy}
  let(:scaler) {TestScaler.new(1)}

  it "scales with no work" do
    system = TestSystem.new(0)
    strategy = cut.new(0)
    strategy.call(system, 1).should == 0
  end

  it "does not scale with pending work" do
    system = TestSystem.new(1)
    strategy = cut.new(0)
    strategy.call(system, 1).should == 1
  end

  it {cut.new(0).timeout.should == 0}
end

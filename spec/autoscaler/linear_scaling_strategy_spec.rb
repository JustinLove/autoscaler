require 'spec_helper'
require 'test_system'
require 'autoscaler/linear_scaling_strategy'

describe Autoscaler::LinearScalingStrategy do
  let(:cut) {Autoscaler::LinearScalingStrategy}

  it "deactivates with no work" do
    system = TestSystem.new(0)
    strategy = cut.new(max_workers: 1)
    expect(strategy.call(system, 1)).to eq 0
  end

  it "activates with some work" do
    system = TestSystem.new(1)
    strategy = cut.new(max_workers: 1)
    expect(strategy.call(system, 1)).to be > 0
  end

  it "minimally scales with minimal work" do
    system = TestSystem.new(1)
    strategy = cut.new(max_workers: 2, worker_capacity: 2)
    expect(strategy.call(system, 1)).to eq 1
  end

  it "maximally scales with too much work" do
    system = TestSystem.new(5)
    strategy = cut.new(max_workers: 2, worker_capacity: 2)
    expect(strategy.call(system, 1)).to eq 2
  end

  it "proportionally scales with some work" do
    system = TestSystem.new(5)
    strategy = cut.new(max_workers: 5, worker_capacity: 2)
    expect(strategy.call(system, 1)).to eq 3
  end

  it "doesn't scale unless minimum is met" do
    system = TestSystem.new(2)
    strategy = cut.new(max_workers: 10, worker_capacity: 4, min_factor: 0.5)
    expect(strategy.call(system, 1)).to eq 0
  end

  it "scales proprotionally with a minimum" do
    system = TestSystem.new(3)
    strategy = cut.new(max_workers: 10, worker_capacity: 4, min_factor: 0.5)
    expect(strategy.call(system, 1)).to eq 1
  end

  it "scales maximally with a minimum" do
    system = TestSystem.new(25)
    strategy = cut.new(max_workers: 5, worker_capacity: 4, min_factor: 0.5)
    expect(strategy.call(system, 1)).to eq 5
  end

  it "scales proportionally with a minimum > 1" do
    system = TestSystem.new(12)
    strategy = cut.new(max_workers: 5, worker_capacity: 4, min_factor: 2)
    expect(strategy.call(system, 1)).to eq 2
  end

  it "scales maximally with a minimum factor > 1" do
    system = TestSystem.new(30)
    strategy = cut.new(max_workers: 5, worker_capacity: 4, min_factor: 2)
    expect(strategy.call(system, 1)).to eq 5
  end

  it "doesn't scale down engaged workers" do
    system = TestSystem.new(0, 2)
    strategy = cut.new(max_workers: 5, worker_capacity: 4)
    expect(strategy.call(system, 1)).to eq 2
  end

  it "doesn't scale above max workers even if engaged workers is greater" do
    system = TestSystem.new(40, 6)
    strategy = cut.new(max_workers: 5, worker_capacity: 4)
    expect(strategy.call(system, 1)).to eq 5
  end

  it "returns zero if requested capacity is zero" do
    system = TestSystem.new(0, 0)
    strategy = cut.new(max_workers: 0, worker_capacity: 0)
    expect(strategy.call(system, 5)).to eq 0
  end

  it "doesn't scale below min workers even without work" do
    system = TestSystem.new(0, 0)
    strategy = cut.new(min_workers: 1)
    expect(strategy.call(system, 1)).to eq 1
  end
end

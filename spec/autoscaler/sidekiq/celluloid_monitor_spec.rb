require 'spec_helper'
require 'test_system'
require 'autoscaler/sidekiq/celluloid_monitor'
require 'timeout'

describe Autoscaler::Sidekiq::CelluloidMonitor do
  before do
    @redis = Sidekiq.redis = REDIS
    Sidekiq.redis {|c| c.flushdb }
  end

  let(:cut) {Autoscaler::Sidekiq::CelluloidMonitor}
  let(:scaler) {TestScaler.new(1)}

  it "scales with no work" do
    system = TestSystem.new(0)
    manager = cut.new(scaler, lambda{|s,t| 0}, system)
    Timeout.timeout(1) { manager.wait_for_downscale(0.5) }
    expect(scaler.workers).to eq(0)
    manager.terminate
  end

  it "does not scale with pending work" do
    system = TestSystem.new(1)
    manager = cut.new(scaler, lambda{|s,t| 1}, system)
    expect {Timeout.timeout(1) { manager.wait_for_downscale(0.5) }}.to raise_error Timeout::Error
    expect(scaler.workers).to eq(1)
    manager.terminate
  end

  it "will downscale with initial workers zero" do
    system = TestSystem.new(0)
    scaler = TestScaler.new(0)
    manager = cut.new(scaler, lambda{|s,t| 0}, system)
    Timeout.timeout(1) { manager.wait_for_downscale(0.5) }
    expect(scaler.workers).to eq(0)
    manager.terminate
  end
end

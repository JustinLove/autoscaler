require 'spec_helper'
require 'autoscaler/sidekiq/celluloid_monitor'
require 'timeout'

class TestSystem
  def initialize(pending)
    @pending = pending
  end

  def working?; false; end
  def pending_work?; @pending; end
end

describe Autoscaler::Sidekiq::CelluloidMonitor do
  before do
    @redis = Sidekiq.redis = REDIS
    Sidekiq.redis {|c| c.flushdb }
  end

  let(:cut) {Autoscaler::Sidekiq::CelluloidMonitor}
  let(:scaler) {TestScaler.new(1)}

  it "scales with no work" do
    system = TestSystem.new(false)
    manager = cut.new(scaler, 0, system)
    Timeout.timeout(1) { manager.wait_for_downscale }
    scaler.workers.should == 0
    manager.terminate
  end

  it "does not scale with pending work" do
    system = TestSystem.new(true)
    manager = cut.new(scaler, 0, system)
    expect {Timeout.timeout(1) { manager.wait_for_downscale }}.to raise_error Timeout::Error
    scaler.workers.should == 1
    manager.terminate
  end
end

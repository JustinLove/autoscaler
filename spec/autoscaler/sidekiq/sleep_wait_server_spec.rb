require 'spec_helper'
require 'autoscaler/sidekiq/sleep_wait_server'

describe Autoscaler::Sidekiq::SleepWaitServer do
  before do
    @redis = Sidekiq.redis = REDIS
    Sidekiq.redis {|c| c.flushdb }
  end

  let(:cut) {Autoscaler::Sidekiq::SleepWaitServer}
  let(:scaler) {TestScaler.new(1)}
  let(:server) {cut.new(scaler, 0, ['queue'])}

  shared_examples "a sleepwait server" do
  it "scales with no work" do
    allow(server).to receive(:pending_work?).and_return(false)
    when_run
    expect(scaler.workers).to eq(0)
  end

  it "does not scale with pending work" do
    allow(server).to receive(:pending_work?).and_return(true)
    when_run
    expect(scaler.workers).to eq(1)
  end
  end

  describe "a middleware with no redis specified" do
  it_behaves_like "a sleepwait server" do
  def when_run
    server.call(Object.new, {}, 'queue') {}
  end
  end
  end

  describe "a middleware with redis specified" do
  it_behaves_like "a sleepwait server" do
  def when_run
    server.call(Object.new, {}, 'queue', Sidekiq.method(:redis)) {}
  end
  end
  end

  it('yields') {expect(server.call(Object.new, {}, 'queue') {:foo}).to eq(:foo)}
end

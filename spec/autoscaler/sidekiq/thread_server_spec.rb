require 'spec_helper'
require 'autoscaler/sidekiq/thread_server'
require 'timeout'

describe Autoscaler::Sidekiq::ThreadServer do
  before do
    @redis = Sidekiq.redis = REDIS
    Sidekiq.redis {|c| c.flushdb }
  end

  let(:cut) {Autoscaler::Sidekiq::ThreadServer}
  let(:scaler) {TestScaler.new(1)}

  describe "thread core" do
    it "scales with no work" do
      server = cut.new(scaler, lambda{|s,t| 0})
      Timeout.timeout(1) { server.run(0.5) }
      expect(scaler.workers).to eq 0
      server.terminate
    end

    it "does not scale with pending work" do
      server = cut.new(scaler, lambda{|s,t| 1})
      expect {Timeout.timeout(1) { server.run(0.5) }}.to raise_error Timeout::Error
      expect(scaler.workers).to eq 1
      server.terminate
    end

    it "will downscale with initial workers zero" do
      scaler = TestScaler.new(0)
      server = cut.new(scaler, lambda{|s,t| 0})
      Timeout.timeout(1) { server.run(0.5) }
      expect(scaler.workers).to eq 0
      server.terminate
    end
  end

  describe "Middleware interface" do
    let(:server) {cut.new(scaler, 0, ['queue'])}

    it('yields') {expect(server.call(Object.new, {}, 'queue') {:foo}).to eq :foo}
    it('yields with a redis pool') {expect(server.call(Object.new, {}, 'queue', Sidekiq.method(:redis)) {:foo}).to eq :foo}
  end
end

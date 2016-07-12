require 'spec_helper'
require 'autoscaler/sidekiq/queue_system'
require 'autoscaler/sidekiq/thread_server'
require 'timeout'

describe Autoscaler::Sidekiq::ThreadServer do
  before do
    @redis = Sidekiq.redis = REDIS
    Sidekiq.redis {|c| c.flushdb }
  end

  let(:middleware) {Autoscaler::Sidekiq::ThreadServer}
  let(:monitor) {Autoscaler::Sidekiq::ThreadServer.const_get(:Monitor)}
  let(:scaler) {TestScaler.new(1)}
  let(:strategy0) {lambda{|s,t| 0}}
  let(:strategy1) {lambda{|s,t| 1}}
  let(:system) {Autoscaler::Sidekiq::QueueSystem.new}

  describe "thread core" do
    it "scales with no work" do
      server = monitor.new
      Timeout.timeout(1) { server.run(scaler, strategy0, system, 0.5) }
      expect(scaler.workers).to eq 0
      server.terminate
    end

    it "does not scale with pending work" do
      server = monitor.new
      expect {Timeout.timeout(1) { server.run(scaler, strategy1, system, 0.5) }}.to raise_error Timeout::Error
      expect(scaler.workers).to eq 1
      server.terminate
    end

    it "will downscale with initial workers zero" do
      scaler = TestScaler.new(0)
      server = monitor.new
      Timeout.timeout(1) { server.run(scaler, strategy0, system, 0.5) }
      expect(scaler.workers).to eq 0
      server.terminate
    end

    it "only starts a single thread " do
      scaler = TestScaler.new(0)
      mon = monitor.new
      $counter = 0
      def mon.run(a, b, c, i = 15)
        $counter += 1
      end
      t1 = Thread.new { mon.wait_for_downscale(scaler, strategy0, system) }
      t2 = Thread.new { mon.wait_for_downscale(scaler, strategy0, system) }
      sleep(0.1)
      t1.value
      t2.value
      expect($counter).to eq 1
      mon.terminate
    end
  end

  describe "Middleware interface" do
    let(:server) {middleware.new(scaler, 0, ['queue'])}

    it('yields') {expect(server.call(Object.new, {}, 'queue') {:foo}).to eq :foo}
    it('yields with a redis pool') {expect(server.call(Object.new, {}, 'queue', Sidekiq.method(:redis)) {:foo}).to eq :foo}
  end
end

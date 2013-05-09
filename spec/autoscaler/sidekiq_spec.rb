require 'spec_helper'
require 'autoscaler/sidekiq'

class Scaler
  attr_accessor :workers

  def initialize(n = 0)
    self.workers = n
  end
end

describe Autoscaler::Sidekiq do
  before do
    @redis = Sidekiq.redis = REDIS
    Sidekiq.redis {|c| c.flushdb }
  end

  let(:scaler) do
    Scaler.new(workers)
  end

  describe Autoscaler::Sidekiq::Client do
    let(:cut) {Autoscaler::Sidekiq::Client}
    let(:client) {cut.new('queue' => scaler)}
    let(:workers) {0}

    describe 'scales' do
      before {client.call(Class, {}, 'queue') {}}
      it {scaler.workers.should == 1}
    end

    describe 'yields' do
      it {client.call(Class, {}, 'queue') {:foo}.should == :foo}
    end
  end

  describe Autoscaler::Sidekiq::Server do
    let(:cut) {Autoscaler::Sidekiq::Server}
    let(:server) {cut.new(scaler, 0, ['queue'])}
    let(:workers) {1}

    def when_run
      server.call(Object.new, {}, 'queue') {}
    end

    it "scales with no work" do
      server.stub(:pending_work?).and_return(false)
      when_run
      scaler.workers.should == 0
    end

    it "does not scale with pending work" do
      server.stub(:pending_work?).and_return(true)
      when_run
      scaler.workers.should == 1
    end

    describe 'yields' do
      it {server.call(Object.new, {}, 'queue') {:foo}.should == :foo}
    end
  end
end

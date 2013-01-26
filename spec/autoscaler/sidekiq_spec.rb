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
      subject {scaler.workers}
      it {should == 1}
    end

    describe 'yields' do
      it {client.call(Class, {}, 'queue') {:foo}.should == :foo}
    end
  end

  describe Autoscaler::Sidekiq::Server do
    let(:cut) {Autoscaler::Sidekiq::Server}
    let(:server) {cut.new(scaler, 0)}
    let(:workers) {1}

    describe 'scales' do
      context "with no work" do
        before do
          server.call(Object.new, {}, 'queue') {}
        end
        subject {scaler.workers}
        it {should == 0}
      end
    end

    describe 'does not scale' do
      context "with enqueued work" do
        before do
          server.stub(:all_queues).and_return({'queue' => 1})
          server.call(Object.new, {}, 'queue') {}
        end
        subject {scaler.workers}
        it {should == 1}
      end

      context "with schedule work" do
        before do
          server.stub(:scheduled_work?).and_return(true)
          server.call(Object.new, {}, 'queue') {}
        end
        subject {scaler.workers}
        it {should == 1}
      end

      context "with retry work" do
        before do
          server.stub(:retry_work?).and_return(true)
          server.call(Object.new, {}, 'queue') {}
        end
        subject {scaler.workers}
        it {should == 1}
      end
    end

    describe 'yields' do
      it {server.call(Object.new, {}, 'queue') {:foo}.should == :foo}
    end
  end
end

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
    let(:sa) {cut.new('queue' => scaler)}
    let(:workers) {0}

    describe 'scales' do
      before {sa.call(Class, {}, 'queue') {}}
      subject {scaler.workers}
      it {should == 1}
    end

    describe 'yields' do
      it {sa.call(Class, {}, 'queue') {:foo}.should == :foo}
    end
  end

  describe Autoscaler::Sidekiq::Server do
    let(:cut) {Autoscaler::Sidekiq::Server}
    let(:sa) {cut.new(scaler, 0)}
    let(:workers) {1}

    describe 'scales' do
      context "with no work" do
        before do
          sa.call(Object.new, {}, 'queue') {}
        end
        subject {scaler.workers}
        it {should == 0}
      end
    end

    describe 'does not scale' do
      context "with enqueued work" do
        before do
          sa.stub(:all_queues).and_return({'queue' => 1})
          sa.call(Object.new, {}, 'queue') {}
        end
        subject {scaler.workers}
        it {should == 1}
      end

      context "with schedule work" do
        before do
          sa.stub(:scheduled_work?).and_return(true)
          sa.call(Object.new, {}, 'queue') {}
        end
        subject {scaler.workers}
        it {should == 1}
      end

      context "with retry work" do
        before do
          sa.stub(:retry_work?).and_return(true)
          sa.call(Object.new, {}, 'queue') {}
        end
        subject {scaler.workers}
        it {should == 1}
      end
    end

    describe 'yields' do
      it {sa.call(Object.new, {}, 'queue') {:foo}.should == :foo}
    end
  end
end

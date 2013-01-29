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

    def with_work_in_set(queue, set)
      payload = Sidekiq.dump_json('queue' => queue)
      Sidekiq.redis { |c| c.zadd(set, (Time.now.to_f + 30.to_f).to_s, payload)}
    end

    def with_scheduled_work_in(queue)
      with_work_in_set(queue, 'schedule')
    end

    def with_retry_work_in(queue)
      with_work_in_set(queue, 'retry')
    end

    def when_run
      server.call(Object.new, {}, 'queue') {}
    end

    def self.when_run_should_scale
      it('should downscale') do
        when_run
        scaler.workers.should == 0
      end
    end

    def self.when_run_should_not_scale
      it('should not downscale') do
        when_run
        scaler.workers.should == 1
      end
    end

    describe 'scales' do
      context "with no work" do
        before do
          server.stub(:all_queues).and_return({'queue' => 0, 'another_queue' => 1})
        end
        when_run_should_scale
      end

      context "with scheduled work in another queue" do
        before do
          with_scheduled_work_in('another_queue')
        end
        when_run_should_scale
      end

      context "with retry work in another queue" do
        before do
          with_retry_work_in('another_queue')
        end
        when_run_should_scale
      end
    end

    describe 'does not scale' do
      context "with enqueued work" do
        before do
          server.stub(:all_queues).and_return({'queue' => 1})
        end
        when_run_should_not_scale
      end

      context "with schedule work" do
        before do
          with_scheduled_work_in('queue')
        end
        when_run_should_not_scale
      end

      context "with retry work" do
        before do
          with_retry_work_in('queue')
        end
        when_run_should_not_scale
      end
    end

    describe 'yields' do
      it {server.call(Object.new, {}, 'queue') {:foo}.should == :foo}
    end
  end
end

require 'spec_helper'
require 'autoscaler/sidekiq/queue_system'

describe Autoscaler::Sidekiq::QueueSystem do
  let(:cut) {Autoscaler::Sidekiq::QueueSystem}

  before do
    @redis = Sidekiq.redis = REDIS
    Sidekiq.redis {|c| c.flushdb }
  end

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

  subject {cut.new(['queue'])}

  it {subject.queue_names.should == ['queue']}
  it {subject.working?.should be_false}

  describe 'no pending work' do
    it "with no work" do
      subject.stub(:sidekiq_queues).and_return({'queue' => 0, 'another_queue' => 1})
      subject.should_not be_pending_work
    end

    it "with scheduled work in another queue" do
      with_scheduled_work_in('another_queue')
      subject.should_not be_pending_work
    end

    it "with retry work in another queue" do
      with_retry_work_in('another_queue')
      subject.should_not be_pending_work
    end
  end

  describe 'with pending work' do
    it "with enqueued work" do
      subject.stub(:sidekiq_queues).and_return({'queue' => 1})
      subject.should be_pending_work
    end

    it "with schedule work" do
      with_scheduled_work_in('queue')
      subject.should be_pending_work
    end

    it "with retry work" do
      with_retry_work_in('queue')
      subject.should be_pending_work
    end
  end
end

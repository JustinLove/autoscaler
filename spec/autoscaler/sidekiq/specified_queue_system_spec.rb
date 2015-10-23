require 'spec_helper'
require 'autoscaler/sidekiq/specified_queue_system'

describe Autoscaler::Sidekiq::SpecifiedQueueSystem do
  let(:cut) {Autoscaler::Sidekiq::SpecifiedQueueSystem}

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

  it {expect(subject.queue_names).to eq ['queue']}
  it {expect(subject.workers).to eq 0}

  describe 'no queued work' do
    it "with no work" do
      allow(subject).to receive(:sidekiq_queues).and_return({'queue' => 0, 'another_queue' => 1})
      expect(subject.queued).to eq 0
    end

    it "with scheduled work in another queue" do
      with_scheduled_work_in('another_queue')
      expect(subject.scheduled).to eq 0
    end

    it "with retry work in another queue" do
      with_retry_work_in('another_queue')
      expect(subject.retrying).to eq 0
    end
  end

  describe 'with queued work' do
    it "with enqueued work" do
      allow(subject).to receive(:sidekiq_queues).and_return({'queue' => 1})
      expect(subject.queued).to eq 1
    end

    it "with schedule work" do
      with_scheduled_work_in('queue')
      expect(subject.scheduled).to eq 1
    end

    it "with retry work" do
      with_retry_work_in('queue')
      expect(subject.retrying).to eq 1
    end
  end
end

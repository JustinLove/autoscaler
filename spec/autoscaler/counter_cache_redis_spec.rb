require 'spec_helper'
require 'autoscaler/counter_cache_redis'

describe Autoscaler::CounterCacheRedis do
  before do
    @redis = Sidekiq.redis = REDIS
    Sidekiq.redis {|c| c.flushdb }
  end

  let(:cut) {Autoscaler::CounterCacheRedis}
  subject {cut.new(Sidekiq.method(:redis))}

  it {expect{subject.counter}.to raise_error(cut::Expired)}
  it {expect(subject.counter{1}).to eq(1)}

  it 'set and store' do
    subject.counter = 2
    expect(subject.counter).to eq(2)
  end

  it 'does not conflict with multiple worker types' do
    other_worker_cache = cut.new(@redis, 300, 'other_worker')
    subject.counter = 1
    other_worker_cache.counter = 2

    expect(subject.counter).to eq(1)
    other_worker_cache.counter = 2
  end

  it 'times out' do
    cache = cut.new(Sidekiq.method(:redis), 1) # timeout 0 invalid
    cache.counter = 3
    sleep(2)
    expect{cache.counter}.to raise_error(cut::Expired)
  end

  it 'passed a connection pool' do
    cache = cut.new(@redis)
    cache.counter = 4
    expect(cache.counter).to eq(4)
  end

  it 'passed a plain connection' do
    connection = Redis.connect(:url => 'http://localhost:9736', :namespace => 'autoscaler')
    cache = cut.new connection
    cache.counter = 5
    expect(cache.counter).to eq(5)
  end
end

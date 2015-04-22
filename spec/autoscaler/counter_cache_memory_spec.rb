require 'spec_helper'
require 'autoscaler/counter_cache_memory'

describe Autoscaler::CounterCacheMemory do
  let(:cut) {Autoscaler::CounterCacheMemory}

  it {expect{cut.new.counter}.to raise_error(cut::Expired)}
  it {expect(cut.new.counter{1}).to eq 1}

  it 'set and store' do
    cache = cut.new
    cache.counter = 1
    expect(cache.counter).to eq 1
  end

  it 'times out' do
    cache = cut.new(0)
    cache.counter = 1
    expect{cache.counter.should}.to raise_error(cut::Expired)
  end
end

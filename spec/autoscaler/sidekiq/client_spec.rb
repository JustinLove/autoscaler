require 'spec_helper'
require 'test_system'
require 'autoscaler/sidekiq/client'

describe Autoscaler::Sidekiq::Client do
  let(:cut) {Autoscaler::Sidekiq::Client}
  let(:scaler) {TestScaler.new(0)}
  let(:client) {cut.new('queue' => scaler)}

  describe 'call' do
    it 'scales' do
      client.call(Class, {}, 'queue') {}
      expect(scaler.workers).to eq 1
    end

    it 'scales with a redis pool' do
      client.call(Class, {}, 'queue', ::Sidekiq.method(:redis)) {}
      expect(scaler.workers).to eq 1
    end

    it('yields') {expect(client.call(Class, {}, 'queue') {:foo}).to eq :foo}
  end

  describe 'initial workers' do
    it 'works with default arguments' do
      client.set_initial_workers
      expect(scaler.workers).to eq 0
    end

    it 'scales when necessary' do
      client.set_initial_workers {|q| TestSystem.new(1)}
      expect(scaler.workers).to eq 1
    end
  end
end

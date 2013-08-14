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
      scaler.workers.should == 1
    end

    it('yields') {client.call(Class, {}, 'queue') {:foo}.should == :foo}
  end

  describe 'initial workers' do
    it 'works with default arguments' do
      client.set_initial_workers
      scaler.workers.should == 0
    end

    it 'scales when necessary' do
      client.set_initial_workers {|q| TestSystem.new(1)}
      scaler.workers.should == 1
    end
  end
end

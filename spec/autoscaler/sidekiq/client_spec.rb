require 'spec_helper'
require 'autoscaler/sidekiq/client'

describe Autoscaler::Sidekiq::Client do
  let(:cut) {Autoscaler::Sidekiq::Client}
  let(:scaler) {TestScaler.new(0)}
  let(:client) {cut.new('queue' => scaler)}

  it 'scales' do
    client.call(Class, {}, 'queue') {}
    scaler.workers.should == 1
  end

  it('yields') {client.call(Class, {}, 'queue') {:foo}.should == :foo}
end

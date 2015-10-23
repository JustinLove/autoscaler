require 'spec_helper'
require 'autoscaler/sidekiq/monitor_middleware_adapter'

describe Autoscaler::Sidekiq::MonitorMiddlewareAdapter do
  before do
    @redis = Sidekiq.redis = REDIS
    Sidekiq.redis {|c| c.flushdb }
  end

  let(:cut) {Autoscaler::Sidekiq::MonitorMiddlewareAdapter}
  let(:scaler) {TestScaler.new(1)}
  let(:server) {cut.new(scaler, 0, ['queue'])}

  it('yields') {expect(server.call(Object.new, {}, 'queue') {:foo}).to eq :foo}
  it('yields with a redis pool') {expect(server.call(Object.new, {}, 'queue', Sidekiq.method(:redis)) {:foo}).to eq :foo}
end

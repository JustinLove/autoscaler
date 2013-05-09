require 'spec_helper'
require 'autoscaler/sidekiq/activity'

describe Autoscaler::Sidekiq::Activity do
  before do
    @redis = Sidekiq.redis = REDIS
    Sidekiq.redis {|c| c.flushdb }
  end

  let(:cut) {Autoscaler::Sidekiq::Activity}
  let(:activity) {cut.new(0)}

  context "when another process is working" do
    let(:other_process) {cut.new(10)}
    before do
      activity.idle!('queue')
      other_process.working!('other_queue')
    end
    it {activity.should be_idle(['queue'])}
  end
end

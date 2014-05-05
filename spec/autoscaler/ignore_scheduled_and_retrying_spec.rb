require 'spec_helper'
require 'test_system'
require 'autoscaler/ignore_scheduled_and_retrying'

describe Autoscaler::IgnoreScheduledAndRetrying do
  let(:cut) {Autoscaler::IgnoreScheduledAndRetrying}

  it "passes through enqueued" do
    system = Struct.new(:enqueued).new(3)
    strategy = proc {|system, time| system.enqueued}
    cut.new(strategy).call(system, 0).should == 3
  end

  it "passes through workers" do
    system = Struct.new(:workers).new(3)
    strategy = proc {|system, time| system.workers}
    cut.new(strategy).call(system, 0).should == 3
  end

  it "ignores scheduled" do
    system = Struct.new(:scheduled).new(3)
    strategy = proc {|system, time| system.scheduled}
    cut.new(strategy).call(system, 0).should == 0
  end

  it "ignores retrying" do
    system = Struct.new(:retrying).new(3)
    strategy = proc {|system, time| system.retrying}
    cut.new(strategy).call(system, 0).should == 0
  end
end



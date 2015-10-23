require 'spec_helper'
require 'autoscaler/heroku_scaler'
require 'heroku/api/errors'

describe Autoscaler::HerokuScaler, :online => true do
  let(:cut) {Autoscaler::HerokuScaler}
  let(:client) {cut.new}
  subject {client}

  its(:workers) {should eq(0)}

  describe 'scaled' do
    around do |example|
      client.workers = 1
      example.call
      client.workers = 0
    end

    its(:workers) {should eq(1)}
  end

  shared_examples 'exception handler' do |exception_class|
    before do
      expect(client).to receive(:client){
        raise exception_class.new(Exception.new('oops'))
      }
    end

    describe "default handler" do
      it {expect{client.workers}.to_not raise_error}
      it {expect(client.workers).to eq(0)}
      it {expect{client.workers = 2}.to_not raise_error}
    end

    describe "custom handler" do
      before do
        @caught = false
        client.exception_handler = lambda {|exception| @caught = true}
      end

      it {client.workers; expect(@caught).to be(true)}
    end
  end

  describe 'exception handling', :focus => true do
    it_behaves_like 'exception handler', Excon::Errors::SocketError
    it_behaves_like 'exception handler', Heroku::API::Errors::Error
  end
end

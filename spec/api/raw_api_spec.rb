require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Api do
  subject(:api) { Uploadcare::Api.new(CONFIG) }

  it "should initialize api" do
    is_expected.to be_an_instance_of(Uploadcare::Api)
  end

  it 'should respond to request methods' do
    is_expected.to respond_to :request
    is_expected.to respond_to :get
    is_expected.to respond_to :post
    is_expected.to respond_to :put
    is_expected.to respond_to :delete
  end

  context 'when performing requests' do
    subject(:request) { api.request }

    it { is_expected.to be_a Hash }
  end
end

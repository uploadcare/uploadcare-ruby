require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Api do
  before :each do
    @api = Uploadcare::Api.new(CONFIG)
  end

  it "should initialize api" do
    @api.should be_an_instance_of(Uploadcare::Api)
  end

  it 'should respond to request methods' do
    @api.should respond_to :request
    @api.should respond_to :get
    @api.should respond_to :post
    @api.should respond_to :put
    @api.should respond_to :delete
  end

  it 'should perform custom requests' do
    expect { @api.request }.to_not raise_error
  end
end

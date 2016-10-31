require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Error do
  before(:all) do
    @settings = Uploadcare.default_settings
    @codes = [400, 401, 403, 404, 406, 408, 422, 429, 500, 502, 503, 504]
    @connection = Uploadcare::Connections::ApiConnection.new(@settings)
  end

  it 'Error codes should be accesbile' do
    Uploadcare::Error.errors.keys.should == @codes
  end

  it 'Errors should be kind of requested codes' do
    not_found = Uploadcare::Error.errors[404]
    not_found.new('File not found').should be_kind_of(Uploadcare::Error::RequestError::NotFound)
  end

  it 'errors should have meaningfull messages' do
    not_found = Uploadcare::Error.errors[404]
    error = not_found.new
    error.message.should == "HTTP 404 - the requested resource could not be found."
  end

  it 'Should raise an error' do
    error = Uploadcare::Error::RequestError::NotFound
    expect{ @connection.send :get, '/random_url/', {} }.to raise_error(error)
  end

  it "should escape particular error" do
    error = Uploadcare::Error::RequestError::NotFound
    expect do
      begin
        @connection.send :get, '/random_url/', {}
      rescue error => e
        nil
      end
    end.to_not raise_error
  end

  it 'should escape common request error' do
    error = Uploadcare::Error::RequestError
    expect do
      begin
        @connection.send :get, '/random_url/', {}
      rescue error => e
        nil
      end
    end.to_not raise_error
  end

  it 'should escape generic uploadcare service error' do
    error = Uploadcare::Error
    expect do
      begin
        @connection.send :get, '/random_url/', {}
      rescue error => e
        nil
      end
    end.to_not raise_error
  end

  it 'should escape generic uploadcare service error' do
    error = StandardError
    expect do
      begin
        @connection.send :get, '/random_url/', {}
      rescue error => e
        nil
      end
    end.to_not raise_error
  end
end

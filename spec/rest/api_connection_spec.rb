require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Connections::ApiConnection do
  before(:all) do
    @settings = Uploadcare.default_settings
  end

  it 'should initialize api connection' do
    expect {Uploadcare::Connections::ApiConnection.new(@settings)}.to_not raise_error
  end

  it 'should use ParseJson and RaiseError middlewares' do
    connection = Uploadcare::Connections::ApiConnection.new(@settings)
    connection.builder.handlers.include?(Uploadcare::Connections::Response::ParseJson).should == true
    connection.builder.handlers.include?(Uploadcare::Connections::Response::RaiseError).should == true
  end
end
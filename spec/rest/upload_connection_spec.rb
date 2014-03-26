require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Connections::UploadConnection do
  before(:all) do
    @settings = Uploadcare.default_settings
  end

  it 'should initialize upload connection' do
    expect {Uploadcare::Connections::UploadConnection.new(@settings)}.to_not raise_error
  end

  it 'should use ParseJson and RaiseError middleware' do
    connection = Uploadcare::Connections::UploadConnection.new(@settings)
    connection.builder.handlers.include?(Uploadcare::Connections::Response::ParseJson).should == true
    connection.builder.handlers.include?(Uploadcare::Connections::Response::RaiseError).should == true
  end
end
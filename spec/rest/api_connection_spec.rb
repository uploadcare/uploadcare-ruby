require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Connections::ApiConnection do
  it 'should initialize api connection' do
    expect {Uploadcare::Connections::ApiConnection.new(Uploadcare.default_settings)}.to_not raise_error
  end
end
require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Connections::UploadConnection do
  it 'should initialize upload connection' do
    expect {Uploadcare::Connections::UploadConnection.new(Uploadcare.default_settings)}.to_not raise_error
  end
end
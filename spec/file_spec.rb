require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Api::File do
  before :each do
    @api = Uploadcare::Api.new(CONFIG)
    @url = "http://macaw.co/images/macaw-logo.png"
    @file = @api.upload @url
  end

  it 'file should be an instance of File' do
    @file.should be_an_instance_of Uploadcare::Api::File
  end

  it 'should have valid url' do
    @file.uuid.should match UUID_REGEX
  end

  it 'should return public url' do
    @file.should respond_to :cdn_url
    @file.should respond_to :public_url
  end

  it 'public url should be valid url' do
    url = @file.cdn_url
    uri = URI.parse(url)
    uri.should be_kind_of(URI::HTTP)
  end
end
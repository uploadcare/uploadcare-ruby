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

  it 'should not be initialized without correct UUID given' do
    expect {Uploadcare::Api::File.new(@api, "not-uuid")}.to raise_error
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

  it 'should be able to load image data' do
    expect {@file.load_data}.to_not raise_error
  end

  it 'should store itself' do
    expect { @file.store }.to_not raise_error
  end

  it 'should be able to tell thenever file was stored' do
  end

  it 'should delete itself' do
    expect { @file.delete }.to_not raise_error
  end

  it 'should be able to tell thenever file was deleted' do
  end

  it 'should construct file from uuid' do
    file = @api.file @file.uuid
    file.should be_kind_of(Uploadcare::Api::File)
  end

  it 'should construct file from cdn url' do
    url = @file.cdn_url + "-/crop/150x150/center/-/format/png/"
    binding.pry
    file = @api.file url
    file.should be_kind_of(Uploadcare::Api::File)
  end
end
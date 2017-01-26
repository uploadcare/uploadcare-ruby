require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Api::File do
  before :each do
    @api = API
    @file = @api.upload IMAGE_URL
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

  it 'file should respond with nil for :stored? and :deleted? methods unless loaded' do
    @file.is_loaded?.should == false
    @file.is_stored?.should == nil
    @file.is_deleted?.should == nil
  end

  it 'should be able to tell thenever file was stored' do
    @file.load
    @file.is_stored?.should == false
    @file.store
    @file.is_stored?.should == true
  end

  it 'should delete itself' do
    expect { @file.delete }.to_not raise_error
  end

  it 'should be able to tell thenever file was deleted' do
    @file.load
    @file.is_deleted?.should == false
    @file.delete
    @file.is_deleted?.should == true
  end

  it 'should construct file from uuid' do
    file = @api.file @file.uuid
    file.should be_kind_of(Uploadcare::Api::File)
  end

  it 'should construct file from cdn url' do
    url = @file.cdn_url + "-/crop/150x150/center/-/format/png/"
    file = @api.file url
    file.should be_kind_of(Uploadcare::Api::File)
  end

  it 'shoul respond to datetime_ methods' do
    @file.load
    @file.should respond_to(:datetime_original)
    @file.should respond_to(:datetime_uploaded)
    @file.should respond_to(:datetime_stored)
    @file.should respond_to(:datetime_removed)
  end

  it 'should respond to datetime_uploaded' do
    @file.load
    @file.datetime_uploaded.should be_kind_of(DateTime)
  end

  it 'should respond to datetime_stored' do
    @file.load
    @file.store
    @file.datetime_stored.should be_kind_of(DateTime)
  end

  it 'should respond to datetime_removed' do
    @file.load
    @file.delete
    @file.datetime_removed.should be_kind_of(DateTime)
    @file.datetime_deleted.should be_kind_of(DateTime)
    @file.datetime_removed.should == @file.datetime_deleted
  end


  it 'should copy itself' do
    # This can cause "File is not ready yet" error if ran too early
    # In this case we retry it 3 times before giving up
    result = retry_if(Uploadcare::Error::RequestError::BadRequest){@file.copy}
    result.should be_kind_of(Hash)
    result["type"].should == "file"
  end


  def retry_if(error, retries=3, &block)
    block.call
  rescue error
    raise if retries <= 0
    sleep 0.2
    retry_if(error, retries-1, &block)
  end

end
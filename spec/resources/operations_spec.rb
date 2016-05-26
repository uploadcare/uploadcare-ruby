require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Api::File, :vcr do
  before :all do
    @api = API
    @file = @api.upload IMAGE_URL
  end

  it "freshly uploaded file should have empty operations list" do
    @file.should respond_to :operations
    @file.operations.should be_kind_of(Array)
    @file.operations.should be_empty
  end

  it "file created from uuid should be not loaded and without operations" do
    file = @api.file @file.uuid
    file.is_loaded?.should be false
    file.operations.should be_empty
  end

  it "file created from url without operations should be not be loaded and have no operations" do
    file = @api.file @file.cdn_url
    file.is_loaded?.should be false
    file.operations.should be_empty
  end

  it "file created from url with operations should be not be loaded and have operations" do
    file = @api.file @file.cdn_url + "-/crop/150x150/center/-/format/png/"
    file.is_loaded?.should be false
    file.operations.should_not be_empty
  end

  it "file should have methods for construct cdn urls with or without cdn operations" do
    @file.should respond_to(:cdn_url_with_operations)
    @file.should respond_to(:cdn_url_without_operations)
  end

  it "file should construct cdn_url with and without opreations" do
    url_without_operations  = @file.cdn_url
    url_with_operations     = @file.cdn_url + "-/crop/150x150/center/-/format/png/"

    file = @api.file url_with_operations

    file.cdn_url.should         == (url_without_operations)
    file.cdn_url(true).should   == (url_with_operations)
  end

  it 'should works also with exact methods' do
    url_without_operations  = @file.cdn_url.to_s
    url_with_operations     = @file.cdn_url + "-/crop/150x150/center/-/format/png/"

    file = @api.file url_with_operations

    file.cdn_url_with_operations.should     == (url_with_operations)
    file.cdn_url_without_operations.should  == (url_without_operations)
  end
end

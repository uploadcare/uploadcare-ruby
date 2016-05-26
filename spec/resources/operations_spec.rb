require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Api::File, :vcr do
  let(:api) { API }
  let(:subject) { api.upload(IMAGE_URL) }

  it { is_expected.to respond_to(:operations) }

  it "freshly uploaded file should have empty operations list" do
    subject.operations.should be_kind_of(Array)
    subject.operations.should be_empty
  end

  it "file created from uuid should be not loaded and without operations" do
    file = api.file(subject.uuid)
    file.is_loaded?.should be false
    file.operations.should be_empty
  end

  it "file created from url without operations should be not be loaded and have no operations" do
    file = api.file subject.cdn_url
    file.is_loaded?.should be false
    file.operations.should be_empty
  end

  it "file created from url with operations should be not be loaded and have operations" do
    file = api.file subject.cdn_url + "-/crop/150x150/center/-/format/png/"
    file.is_loaded?.should be false
    file.operations.should_not be_empty
  end

  it { is_expected.to respond_to(:cdn_url_with_operations) }
  it { is_expected.to respond_to(:cdn_url_without_operations) }

  it "file should construct cdn_url with and without opreations" do
    url_without_operations  = subject.cdn_url
    url_with_operations     = subject.cdn_url + "-/crop/150x150/center/-/format/png/"

    file = api.file url_with_operations

    file.cdn_url.should         == (url_without_operations)
    file.cdn_url(true).should   == (url_with_operations)
  end

  it 'should works also with exact methods' do
    url_without_operations  = subject.cdn_url.to_s
    url_with_operations     = subject.cdn_url + "-/crop/150x150/center/-/format/png/"

    file = api.file url_with_operations

    file.cdn_url_with_operations.should     == (url_with_operations)
    file.cdn_url_without_operations.should  == (url_without_operations)
  end
end

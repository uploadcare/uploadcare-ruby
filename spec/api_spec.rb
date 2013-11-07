require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Api do
  before :each do
    @api = Uploadcare::Api.new(CONFIG)
  end

  it 'should upload file or url' do
    file = @api.upload 'file'
    file.should be_an_instance_of Uploadcare::File
  end

  it 'should upload file' do
    file = @api.upload 'file'
    file.should be_an_instance_of Uploadcare::File
  end

  it 'should upload from url' do
    file = @api.upload 'url'
    file.should be_an_instance_of Uploadcare::File
  end
end
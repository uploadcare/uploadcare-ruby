require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Api do
  before :each do
    @api = Uploadcare::Api.new(CONFIG)
    @file = File.open(File.join(File.dirname(__FILE__), 'view.png'))
    @url = "http://some.com/"
  end

  it 'should upload file or url' do
    file = @api.upload @file
    file.should be_an_instance_of Uploadcare::Api::File
  end

  it 'should raise an error when neither file nor url given' do
    expect { @api.upload 12 }.to raise_error
  end

  it 'should upload file' do
    file = @api.upload @file
    file.should be_an_instance_of Uploadcare::Api::File
  end

  it 'should upload from url' do
    file = @api.upload @url
    file.should be_an_instance_of Uploadcare::Api::File
  end

  it 'should not upload from invalid url' do
    expect { @api.upload 'not.url.' }.to raise_error
  end
end
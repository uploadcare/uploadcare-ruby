require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Api do
  before :all do
    @api = API
    @file = FILE1
    @url = IMAGE_URL
  end

  it 'should upload file or url' do
    file = @api.upload @file
    file.should be_an_instance_of Uploadcare::Api::File
  end

  it 'should raise an error when neither file nor url given' do
    expect { @api.upload 12 }.to raise_error ArgumentError
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
    expect { @api.upload 'not.url.' }.to raise_error, ArgumentError
  end

  it 'uploaded file should have valid UUID' do
    file = @api.upload @url
    file.should be_an_instance_of Uploadcare::Api::File
    file.uuid.should match UUID_REGEX
  end
end

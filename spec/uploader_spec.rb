require 'spec_helper'

describe Uploadcare::Uploader do
  before :each do
    @api = Uploadcare::Api.new(CONFIG)
    @uploader = Uploadcare::Uploader.new(CONFIG)
  end

  it "should upload file with valid public key" do
    file_id = ''
    expect {
      file_id = @uploader.upload_file File.join(File.dirname(__FILE__), 'view.png')
    }.to_not raise_error

    file_id.size.should > 0
  end

  it 'should upload file from url' do
    file = @api.file(@uploader.upload_url('https://uploadcare.com'))
    file.should be_an_instance_of Uploadcare::Api::File
  end

  it 'should require valid public key for file upload' do
    expect {
      uploader = Uploadcare::Uploader.new CONFIG.merge({public_key: 'invalid'})
      uploader.upload_file File.join(File.dirname(__FILE__), 'view.png')
    }.to raise_error
  end
end

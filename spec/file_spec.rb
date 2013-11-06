require 'spec_helper'

describe Uploadcare::Api::File do
  before :each do
    @api = Uploadcare::Api.new(CONFIG)
    @uploader = Uploadcare::Uploader.new(CONFIG)
    @file_id = @uploader.upload_file File.join(File.dirname(__FILE__), 'view.png')
    @file = @api.file(@file_id)
  end

  it 'should be able to store self' do
    @file.store
    @file.datetime_stored.should be
  end

  it 'should be able to delete self' do
    @file.delete
    @file.datetime_removed.should be
  end

  it 'should show upload_date as Time' do
    @file.datetime_uploaded.should be_an_instance_of(Time)
  end

  it 'should show last_keep_claim as Time' do
    @file.store
    @file.datetime_stored.should be_an_instance_of(Time)
  end

  it 'should show removed as Time' do
    @file.delete
    @file.datetime_removed.should be_an_instance_of(Time)
  end

  it 'can generate public url' do
    @file.store
    @file.public_url('crop/200x200', 'resize/200x200').should ==
      "#{CONFIG[:static_url_base]}/#{@file_id}/-/crop/200x200/-/resize/200x200/"
    @file.public_url.should == "#{CONFIG[:static_url_base]}/#{@file_id}/"
  end

  it 'can parse operations' do
    @file = @api.file("#{@file_id}/-/crop/200x200/-/resize/200x200/")
    @file.operations.should == ['crop/200x200', 'resize/200x200']
  end

  it 'can combine operations' do
    @file = @api.file("#{@file_id}/-/crop/200x200/")
    @file.public_url('resize/200x200').should ==
      "#{CONFIG[:static_url_base]}/#{@file_id}/-/crop/200x200/-/resize/200x200/"
    @file.public_url.should == "#{CONFIG[:static_url_base]}/#{@file_id}/-/crop/200x200/"
  end
end

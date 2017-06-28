require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Api::Group do
  before :all do
    @api = API
    @files = @api.upload FILES_ARY
  end

  it "should return group object" do
    group = @api.create_group @files
    group.should be_kind_of(Uploadcare::Api::Group)
  end

  it "should have valid UUID and count of files" do
    group = @api.create_group @files
    group.should respond_to(:uuid)
    group.should respond_to(:files_count)
  end

  it "should may have files" do
    group = @api.create_group @files
    group.should respond_to(:files)
    group.files.should be_kind_of(Array)
    group.files.each do |file|
      file.should be_kind_of(Uploadcare::Api::File)
    end
  end

  it "should create group by id" do
    group = @api.create_group @files

    expect {group_uloaded = @api.group group.uuid}.to_not raise_error
  end

  it "should create loaded and unloaded groups" do
    group = @api.create_group @files
    group_uloaded = @api.group group.uuid
    group.is_loaded?.should be true
    group_uloaded.is_loaded?.should be false
  end

  it "group should load data" do
    group = @api.create_group @files
    group_uloaded = @api.group group.uuid
    group_uloaded.should respond_to(:load_data)
    expect {group_uloaded.load_data}.to_not raise_error
    group_uloaded.is_loaded?.should be true
  end

  it "group should store itself" do
    group = @api.create_group @files
    expect {group.store}.to_not raise_error
  end

  it "should be able to tell when group is stored" do
    group = @api.create_group @files
    group_unloaded = @api.group group.uuid

    group_unloaded.is_loaded?.should == false
    group_unloaded.is_stored?.should == nil

    group_unloaded.load
    group_unloaded.is_stored?.should == false

    group_unloaded.store
    group_unloaded.is_stored?.should == true
  end

  it "should automatically store based on params" do
    @files = @api.upload FILES_ARY, true
    group = @api.create_group @files

    group.load
    group.is_stored?.should == true
  end

  it "group should have datetime attributes" do
    group = @api.create_group @files
    group.should respond_to(:datetime_created)
    group.should respond_to(:datetime_stored)
  end

  it "group should have datetime_created as DateTime object" do
    group = @api.create_group @files
    group.datetime_created.should be_kind_of(DateTime)
  end

  it "group should have datetime_created as DateTime object" do
    group = @api.create_group @files
    group.store
    group.datetime_stored.should be_kind_of(DateTime)
  end

  it "should return cdn string for file in group by it index" do
    group = @api.create_group @files

    file_cdn_url = group.file_cdn_url(0)

    file_cdn_url.should be_kind_of(String)
    file_cdn_url.should == group.cdn_url + "nth/0/"
  end 

  it 'should raise an error if index is greater than files count in group' do
    group = @api.create_group @files
    expect {group.file_cdn_url(5)}.to raise_error
  end
end
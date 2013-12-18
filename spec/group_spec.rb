require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Api::Group do
  before :each do
    @api = Uploadcare::Api.new(CONFIG)
    @file = File.open(File.join(File.dirname(__FILE__), 'view.png'))
    @file2 = File.open(File.join(File.dirname(__FILE__), 'view2.jpg'))
    @files_ary = [@file, @file2]
    @files = @api.upload @files_ary
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
    group.is_loaded?.should be_true
    group_uloaded.is_loaded?.should be_false
  end

  it "group should load data" do
    group = @api.create_group @files
    group_uloaded = @api.group group.uuid
    group_uloaded.should respond_to(:load_data)
    expect {group_uloaded.load_data}.to_not raise_error
    group_uloaded.is_loaded?.should be_true
  end
end
require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Api do
  before :all do
    @api = API
    @files_ary = FILES_ARY
  end

  it "it should upload multiple files" do
    expect {files = @api.upload @files_ary}.to_not raise_error
  end

  it "should retunrn an array of files" do
    files = @api.upload @files_ary
    files.should be_kind_of(Array)
  end

  it "each in array should be UC file object" do
    files = @api.upload @files_ary
    files.each do |f|
      f.should be_kind_of(Uploadcare::Api::File)
    end
  end

  it "each in array should have valid UUID" do 
    files = @api.upload @files_ary
    files.each do |f|
      f.should respond_to(:uuid)
      f.uuid.should match(UUID_REGEX)
    end
  end

  it "each in array should load data for uploaded file" do 
    files = @api.upload @files_ary
    files.each do |f|
      f.should respond_to(:load_data)
      expect {f.load_data}.to_not raise_error
    end
  end
end


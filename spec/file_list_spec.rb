require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Api::File do
  before :each do
    @api = Uploadcare::Api.new(CONFIG)
    @url = "http://macaw.co/images/macaw-logo.png"
    @list = @api.file_list 1
  end

  it "should return file list" do
    @list.should be_kind_of(Uploadcare::Api::FileList)
    binding.pry
  end

  it "should respont to results method" do
    @list.should respond_to :results
  end

  it "results should be an array" do
    @list.results.should be_kind_of(Array)
  end

  it "resulst should be UC files" do
    @list.results.each do |file|
      file.should be_kind_of(Uploadcare::Api::File)
    end
  end

  it "results should be not only files, but loaded files" do
    @list.results.each do |file|
      file.is_loaded?.should be_true
    end
  end

  it "should load next page" do
    next_page = @list.next_page
    next_page.should be_kind_of(Uploadcare::Api::FileList)
  end

  it "should load prev page" do
    list =  @api.file_list 3
    prev_page = list.previous_page
    prev_page.should be_kind_of(Uploadcare::Api::FileList)
  end

  it "should load custom page" do
    page = @list.go_to(@list.pages - 1)
    page.should be_kind_of(Uploadcare::Api::FileList)
  end

  it "should not load next page if there isn't one" do
    page= @list.go_to @list.pages
    page.next_page.should be_nil
  end

  it "should not load prev page if there isn't one" do
    @list.previous_page.should be_nil
  end

  it "should not load custom page with index more than there is actually page in project" do
    page = @list.go_to @list.pages + 3
    page.should be_nil
  end
end
require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Api::File, vcr: { cassette_name: :file_list } do
  let(:api) { API }
  let(:list) { api.file_list(1) }

  it "should return file list" do
    list.should be_kind_of(Uploadcare::Api::FileList)
  end

  it "should respont to results method" do
    list.should respond_to :results
  end

  it "results should be an array" do
    list.results.should be_kind_of(Array)
  end

  it "resulst should be UC files" do
    list.results.each do |file|
      file.should be_kind_of(Uploadcare::Api::File)
    end
  end

  it "results should be not only files, but loaded files" do
    list.results.each do |file|
      file.is_loaded?.should be true
    end
  end

  it "should load next page" do
    next_page = list.next_page
    next_page.should be_kind_of(Uploadcare::Api::FileList)
  end

  it "should load prev page" do
    expect(api.file_list(3)).to be_a(Uploadcare::Api::FileList)
  end

  it "should load custom page" do
    page = list.go_to(list.pages - 1)
    expect(page.next_page).to be_kind_of(Uploadcare::Api::FileList)
  end

  it "should not load next page if there isn't one",
    vcr: { cassette_name: :file_list_last } do
    page = list.go_to(list.pages)
    expect( page.next_page ).to be_nil
  end

  it "should not load prev page if there isn't one" do
    list.previous_page.should be_nil
  end

  it "should not load custom page with index more than there is actually page in project" do
    page = list.go_to list.pages + 3
    page.should be_nil
  end
end

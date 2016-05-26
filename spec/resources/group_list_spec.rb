require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Api::File, vcr: { cassette_name: :file_list} do
  before :all do
    @api = API
    @list = @api.group_list
  end

  it "basic group list" do
    @list.should be_kind_of Uploadcare::Api::GroupList
  end

  it "should contain groups and results" do
    @list.should respond_to(:results)
    @list.should respond_to(:groups)
    @list.groups.should be_kind_of(Array)
  end

  it "results should contain groups" do
    group = @list.groups.sample
    group.should be_kind_of(Uploadcare::Api::Group)
  end

  it "group should no be loaded" do
    group = @list.groups.sample
    group.is_loaded?.should == false
  end
end

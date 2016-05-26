require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Api::File, vcr: { cassette_name: :group_list } do
  let(:api) { API }
  let(:list) { api.group_list }
  let(:group) { list.groups.sample }


  pending "basic group list" do
    list.should be_kind_of Uploadcare::Api::GroupList
  end

  pending "should contain groups and results" do
    list.should respond_to(:results)
    list.should respond_to(:groups)
    list.groups.should be_kind_of(Array)
  end

  pending "results should contain groups" do
    group.should be_kind_of(Uploadcare::Api::Group)
  end

  pending "group should no be loaded" do
    group.is_loaded?.should == false
  end
end

require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Api::Project do
  before :each do
    @api = Uploadcare::Api.new(CONFIG)
    @project = @api.project
  end

  it "should instantiated project" do
    @project.should be_kind_of Uploadcare::Api::Project
  end

  it "should respond to project api methods" do
    @project.should respond_to :collaborators
    @project.should respond_to :name
    @project.should respond_to :pub_key
    @project.should respond_to :autostore_enabled
  end
end
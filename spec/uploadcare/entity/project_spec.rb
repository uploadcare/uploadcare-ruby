require 'spec_helper'

module Uploadcare
  RSpec.describe Project do
    before do
      VCR.use_cassette('project') do
        @project = Project.show
      end
    end

    it "is instantiated project" do
      expect(@project).to be_kind_of Uploadcare::Project
    end

    it "is respond to project api methods" do
      expect(@project).to respond_to :collaborators
      expect(@project).to respond_to :name
      expect(@project).to respond_to :pub_key
      expect(@project).to respond_to :autostore_enabled
    end
  end
end

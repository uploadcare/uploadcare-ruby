# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  RSpec.describe Project do
    before do
      VCR.use_cassette('project') do
        @project = Project.show
      end
    end

    it 'represents a project as an entity' do
      expect(@project).to be_kind_of Uploadcare::Project
    end

    it 'responds to project api methods' do
      expect(@project).to respond_to(:collaborators, :name, :pub_key, :autostore_enabled)
    end
  end
end

# frozen_string_literal: true

module Uploadcare
  class Project < BaseResource
    attr_accessor :name, :pub_key, :autostore_enabled, :collaborators

    def initialize(attributes = {}, config = Uploadcare.configuration)
      super
      @project_client = Uploadcare::ProjectClient.new(config)
      assign_attributes(attributes)
    end

    # Fetches project information
    # @return [Uploadcare::Project] The Project instance with populated attributes
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Project
    def self.show(config = Uploadcare.configuration)
      project_client = Uploadcare::ProjectClient.new(config)
      response = project_client.show
      new(response, config)
    end
  end
end

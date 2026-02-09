# frozen_string_literal: true

# Project resource.
class Uploadcare::Project < Uploadcare::BaseResource
  attr_accessor :name, :pub_key, :autostore_enabled, :collaborators

  def initialize(attributes = {}, config = Uploadcare.configuration)
    super
  end

  # Fetches project information
  # @return [Uploadcare::Project] The Project instance with populated attributes
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Project
  def self.show(config: Uploadcare.configuration, request_options: {})
    project_client = Uploadcare::ProjectClient.new(config: config)
    response = Uploadcare::Result.unwrap(project_client.show(request_options: request_options))
    new(response, config)
  end
end

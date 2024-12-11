# frozen_string_literal: true

module Uploadcare
  class ProjectClient < RestClient
    # Fetches the current project information
    # @return [Hash] The response containing the project details
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Project
    def show
      get('/project/')
    end
  end
end

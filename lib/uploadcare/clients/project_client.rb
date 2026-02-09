# frozen_string_literal: true

# Client for project information.
class Uploadcare::ProjectClient < Uploadcare::RestClient
  # Fetches the current project information
  # @return [Hash] The response containing the project details
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Project
  def show(request_options: {})
    get(path: '/project/', params: {}, headers: {}, request_options: request_options)
  end
end

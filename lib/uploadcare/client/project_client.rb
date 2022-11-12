# frozen_string_literal: true

require_relative 'rest_client'

module Uploadcare
  module Client
    # API client for getting project info
    # @see https://uploadcare.com/docs/api_reference/rest/handling_projects/
    class ProjectClient < RestClient
      # get information about current project
      # current project is determined by public and secret key combination
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Project
      def show
        get(uri: '/project/')
      end

      alias project show
    end
  end
end

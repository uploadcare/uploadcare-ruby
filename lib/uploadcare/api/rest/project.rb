# frozen_string_literal: true

# REST API endpoint for project information.
#
# @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Project
module Uploadcare
  module Api
    class Rest
      class Project
        # @return [Uploadcare::Api::Rest] Parent REST client
        attr_reader :rest

        # @param rest [Uploadcare::Api::Rest] Parent REST client
        def initialize(rest:)
          @rest = rest
        end

        # Get current project information.
        #
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Project details (name, pub_key, autostore_enabled, collaborators)
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Project
        def show(request_options: {})
          rest.get(path: '/project/', params: {}, headers: {}, request_options: request_options)
        end
      end
    end
  end
end

# frozen_string_literal: true

# Project resource representing the current Uploadcare project.
#
# @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Project
module Uploadcare
  module Resources
    class Project < BaseResource
      attr_accessor :name, :pub_key, :autostore_enabled, :collaborators

      # Get current project information.
      #
      # @param client [Uploadcare::Client, nil] Client instance
      # @param config [Uploadcare::Configuration] Configuration fallback
      # @param request_options [Hash] Request options
      # @return [Uploadcare::Resources::Project]
      def self.current(client: nil, config: Uploadcare.configuration, request_options: {})
        resolved_client = resolve_client(client: client, config: config)
        response = Uploadcare::Result.unwrap(
          resolved_client.api.rest.project.show(request_options: request_options)
        )
        new(response, resolved_client)
      end

      class << self
        alias show current
      end
    end
  end
end

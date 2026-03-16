# frozen_string_literal: true

require 'uri'

# REST API endpoint for group operations.
#
# @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Group
module Uploadcare
  module Api
    class Rest
      class Groups
        # @return [Uploadcare::Api::Rest] Parent REST client
        attr_reader :rest

        # @param rest [Uploadcare::Api::Rest] Parent REST client
        def initialize(rest:)
          @rest = rest
        end

        # List groups with optional filtering and pagination.
        #
        # @param params [Hash] Query parameters (limit, ordering, etc.)
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Paginated group list
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Group/operation/groupsList
        def list(params: {}, request_options: {})
          rest.get(path: '/groups/', params: params, headers: {}, request_options: request_options)
        end

        # Get group information by UUID.
        #
        # @param uuid [String] Group UUID (formatted as UUID~size)
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Group details
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Group/operation/groupInfo
        def info(uuid:, request_options: {})
          encoded_uuid = URI::DEFAULT_PARSER.escape(uuid.to_s, /[^A-Za-z0-9\-._~]/)
          rest.get(path: "/groups/#{encoded_uuid}/", params: {}, headers: {}, request_options: request_options)
        end

        # Delete a group by UUID.
        #
        # @param uuid [String] Group UUID (formatted as UUID~size)
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result]
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Group/operation/deleteGroup
        def delete(uuid:, request_options: {})
          encoded_uuid = URI::DEFAULT_PARSER.escape(uuid.to_s, /[^A-Za-z0-9\-._~]/)
          rest.request(method: :delete, path: "/groups/#{encoded_uuid}/", params: {}, headers: {},
                       request_options: request_options)
        end
      end
    end
  end
end

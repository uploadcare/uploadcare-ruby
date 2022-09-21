# frozen_string_literal: true

require_relative 'rest_client'

module Uploadcare
  module Client
    # @see https://uploadcare.com/api-refs/rest-api/v0.5.0/#tag/Group/paths/~1groups~1%3Cuuid%3E~1storage~1/put
    class RestGroupClient < RestClient
      # store all files in a group
      # @see https://uploadcare.com/api-refs/rest-api/v0.5.0/#tag/Group/paths/~1groups~1%3Cuuid%3E~1storage~1/put
      def store(uuid)
        put(uri: "/groups/#{uuid}/storage/")
      end

      # return paginated list of groups
      # @see https://uploadcare.com/api-refs/rest-api/v0.5.0/#operation/groupsList
      def list(options = {})
        query = options.empty? ? '' : "?#{URI.encode_www_form(options)}"
        get(uri: "/groups/#{query}")
      end

      # Delete a file group by its ID.
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/deleteGroup
      def delete(uuid)
        request(method: 'DELETE', uri: "/groups/#{uuid}/")
      end
    end
  end
end

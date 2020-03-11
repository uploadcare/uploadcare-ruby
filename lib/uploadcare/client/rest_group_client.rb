# frozen_string_literal: true

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

      def list(**options)
        query = options.empty? ? '' : '?' + URI.encode_www_form(options)
        get(uri: "/groups/#{query}")
      end
    end
  end
end

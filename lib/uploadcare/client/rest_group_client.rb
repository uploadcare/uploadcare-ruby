# frozen_string_literal: true

require_relative 'rest_client'

module Uploadcare
  module Client
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Group/paths/~1groups~1%3Cuuid%3E~1storage~1/put
    class RestGroupClient < RestClient
      # store all files in a group
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/storeFile
      def store(uuid)
        files = info(uuid).success[:files].compact
        client = ::Uploadcare::Client::FileClient.new
        files.each_slice(Uploadcare.config.file_chunk_size) do |file_chunk|
          file_chunk.each do |file|
            client.store(file[:uuid])
          end
        end

        Dry::Monads::Result::Success.call(nil)
      end

      # Get a file group by its ID.
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/groupInfo
      def info(uuid)
        get(uri: "/groups/#{uuid}/")
      end

      # return paginated list of groups
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/groupsList
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

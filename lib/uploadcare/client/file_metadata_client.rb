# frozen_string_literal: true

require_relative 'rest_client'

module Uploadcare
  module Client
    # API client for handling single metadata_files
    # @see https://uploadcare.com/docs/file-metadata/
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata
    class FileMetadataClient < RestClient
      # Get file's metadata keys and values
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/fileMetadata
      def index(uuid)
        get(uri: "/files/#{uuid}/metadata/")
      end

      # Get the value of a single metadata key.
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/fileMetadataKey
      def show(uuid, key)
        get(uri: "/files/#{uuid}/metadata/#{key}/")
      end

      # Update the value of a single metadata key. If the key does not exist, it will be created.
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/updateFileMetadataKey
      def update(uuid, key, value)
        put(uri: "/files/#{uuid}/metadata/#{key}/", content: value.to_json)
      end

      # Delete a file's metadata key.
      # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/deleteFileMetadataKey
      def delete(uuid, key)
        request(method: 'DELETE', uri: "/files/#{uuid}/metadata/#{key}/")
      end
    end
  end
end

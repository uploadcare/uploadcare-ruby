# frozen_string_literal: true

module Uploadcare
  class FileMetadataClient < RestClient
    # Retrieves all metadata associated with a specific file by UUID.
    # @param uuid [String] The UUID of the file.
    # @return [Hash] A hash containing all metadata key-value pairs for the file.
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/_fileMetadata
    def index(uuid)
      get("/files/#{uuid}/metadata/")
    end

    # Gets the value of a specific metadata key for a file by UUID
    # @param uuid [String] The UUID of the file
    # @param key [String] The metadata key
    # @return [String] The value of the metadata key
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/fileMetadata
    def show(uuid, key)
      get("/files/#{uuid}/metadata/#{key}/")
    end

    # Updates or creates a metadata key for a specific file by UUID
    # @param uuid [String] The UUID of the file
    # @param key [String] The key of the metadata
    # @param value [String] The value of the metadata
    # @return [String] The value of the updated or added metadata key
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/updateFileMetadataKey
    def update(uuid, key, value)
      put("/files/#{uuid}/metadata/#{key}/", value)
    end

    # Deletes a specific metadata key for a file by UUID
    # @param uuid [String] The UUID of the file
    # @param key [String] The metadata key to delete
    # @return [Nil] Returns nil on successful deletion
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/deleteFileMetadata
    def delete(uuid, key)
      del("/files/#{uuid}/metadata/#{key}/")
    end
  end
end

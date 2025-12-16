# frozen_string_literal: true

module Uploadcare
  class FileMetadata < BaseResource
    ATTRIBUTES = %i[
      datetime_removed datetime_stored datetime_uploaded is_image is_ready mime_type original_file_url
      original_filename size url uuid variations content_info appdata source
    ].freeze

    attr_accessor(*ATTRIBUTES)
    # Custom metadata is handled separately to allow for arbitrary key-value pairs
    attr_accessor :metadata

    def initialize(attributes = {}, config = Uploadcare.configuration)
      super
      @file_metadata_client = Uploadcare::FileMetadataClient.new(config)
      @metadata = {}
    end

    # Retrieves metadata for the file
    # @return [Hash] The metadata keys and values for the file
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/_fileMetadata
    # TODO - Remove uuid if the operation is being performed on same file
    def index(uuid)
      response = @file_metadata_client.index(uuid)
      @metadata = response || {}
      self
    end

    # Updates metadata key's value
    # @return [String] The updated value of the metadata key
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/updateFileMetadataKey
    # TODO - Remove uuid if the operation is being performed on same file
    def update(uuid, key, value)
      @file_metadata_client.update(uuid, key, value)
    end

    # Retrieves the value of a specific metadata key for the file
    # @param key [String] The metadata key to retrieve
    # @return [String] The value of the metadata key
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/fileMetadata
    # TODO - Remove uuid if the operation is being performed on same file
    def show(uuid, key)
      @file_metadata_client.show(uuid, key)
    end

    # Deletes a specific metadata key for the file
    # @param key [String] The metadata key to delete
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/deleteFileMetadata
    # TODO - Remove uuid if the operation is being performed on same file
    def delete(uuid, key)
      @file_metadata_client.delete(uuid, key)
    end

    # Class methods for v4.4.3 compatibility

    # Get file's metadata keys and values
    # @param uuid [String] The UUID of the file
    # @param config [Uploadcare::Configuration] Configuration object
    # @return [Hash] The metadata keys and values for the file
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/_fileMetadata
    def self.index(uuid, config = Uploadcare.configuration)
      file_metadata_client = Uploadcare::FileMetadataClient.new(config)
      file_metadata_client.index(uuid)
    end

    # Get the value of a single metadata key
    # @param uuid [String] The UUID of the file
    # @param key [String] The metadata key
    # @param config [Uploadcare::Configuration] Configuration object
    # @return [String] The value of the metadata key
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/fileMetadata
    def self.show(uuid, key, config = Uploadcare.configuration)
      file_metadata_client = Uploadcare::FileMetadataClient.new(config)
      file_metadata_client.show(uuid, key)
    end

    # Update the value of a single metadata key. If the key does not exist, it will be created
    # @param uuid [String] The UUID of the file
    # @param key [String] The metadata key
    # @param value [String] The metadata value
    # @param config [Uploadcare::Configuration] Configuration object
    # @return [String] The value of the updated or added metadata key
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/updateFileMetadataKey
    def self.update(uuid, key, value, config = Uploadcare.configuration)
      file_metadata_client = Uploadcare::FileMetadataClient.new(config)
      file_metadata_client.update(uuid, key, value)
    end

    # Delete a file's metadata key
    # @param uuid [String] The UUID of the file
    # @param key [String] The metadata key to delete
    # @param config [Uploadcare::Configuration] Configuration object
    # @return [Nil] Returns nil on successful deletion
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/deleteFileMetadata
    def self.delete(uuid, key, config = Uploadcare.configuration)
      file_metadata_client = Uploadcare::FileMetadataClient.new(config)
      file_metadata_client.delete(uuid, key)
    end
  end
end

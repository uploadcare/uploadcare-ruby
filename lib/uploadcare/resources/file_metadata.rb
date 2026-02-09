# frozen_string_literal: true

# File metadata resource.
class Uploadcare::FileMetadata < Uploadcare::BaseResource
  def initialize(attributes = {}, config = Uploadcare.configuration)
    super
    @file_metadata_client = Uploadcare::FileMetadataClient.new(config: config)
    @metadata = {}
  end

  # Retrieves metadata for the file
  # @return [Hash] The metadata keys and values for the file
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/_fileMetadata
  def index(uuid: nil, request_options: {})
    response = Uploadcare::Result.unwrap(@file_metadata_client.index(uuid: uuid || @uuid,
                                                                     request_options: request_options))
    @metadata = response if response.is_a?(Hash)
    self
  end

  # Access metadata values dynamically
  def [](key)
    @metadata[key.to_s]
  end

  # Set metadata values dynamically
  def []=(key, value)
    @metadata[key.to_s] = value
  end

  # Return all metadata as a hash
  def to_h
    @metadata.dup
  end

  # Updates metadata key's value
  # @return [String] The updated value of the metadata key
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/updateFileMetadataKey
  def update(key:, value:, uuid: nil, request_options: {})
    Uploadcare::Result.unwrap(@file_metadata_client.update(uuid: uuid || @uuid, key: key, value: value,
                                                           request_options: request_options))
  end

  # Retrieves the value of a specific metadata key for the file
  # @param key [String] The metadata key to retrieve
  # @return [String] The value of the metadata key
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/fileMetadata
  def show(key:, uuid: nil, request_options: {})
    Uploadcare::Result.unwrap(@file_metadata_client.show(uuid: uuid || @uuid, key: key,
                                                         request_options: request_options))
  end

  # Deletes a specific metadata key for the file
  # @param key [String] The metadata key to delete
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/deleteFileMetadata
  def delete(key:, uuid: nil, request_options: {})
    Uploadcare::Result.unwrap(@file_metadata_client.delete(uuid: uuid || @uuid, key: key,
                                                           request_options: request_options))
  end

  # Get file's metadata keys and values
  # @param uuid [String] The UUID of the file
  # @param config [Uploadcare::Configuration] Configuration object
  # @return [Hash] The metadata keys and values for the file
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/_fileMetadata
  def self.index(uuid:, config: Uploadcare.configuration, request_options: {})
    file_metadata_client = Uploadcare::FileMetadataClient.new(config: config)
    Uploadcare::Result.unwrap(file_metadata_client.index(uuid: uuid, request_options: request_options))
  end

  # Get the value of a single metadata key
  # @param uuid [String] The UUID of the file
  # @param key [String] The metadata key
  # @param config [Uploadcare::Configuration] Configuration object
  # @return [String] The value of the metadata key
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/fileMetadata
  def self.show(uuid:, key:, config: Uploadcare.configuration, request_options: {})
    file_metadata_client = Uploadcare::FileMetadataClient.new(config: config)
    Uploadcare::Result.unwrap(file_metadata_client.show(uuid: uuid, key: key, request_options: request_options))
  end

  # Update the value of a single metadata key. If the key does not exist, it will be created
  # @param uuid [String] The UUID of the file
  # @param key [String] The metadata key
  # @param value [String] The metadata value
  # @param config [Uploadcare::Configuration] Configuration object
  # @return [String] The value of the updated or added metadata key
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/updateFileMetadataKey
  def self.update(uuid:, key:, value:, config: Uploadcare.configuration, request_options: {})
    file_metadata_client = Uploadcare::FileMetadataClient.new(config: config)
    Uploadcare::Result.unwrap(file_metadata_client.update(uuid: uuid, key: key, value: value,
                                                          request_options: request_options))
  end

  # Delete a file's metadata key
  # @param uuid [String] The UUID of the file
  # @param key [String] The metadata key to delete
  # @param config [Uploadcare::Configuration] Configuration object
  # @return [Nil] Returns nil on successful deletion
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/deleteFileMetadata
  def self.delete(uuid:, key:, config: Uploadcare.configuration, request_options: {})
    file_metadata_client = Uploadcare::FileMetadataClient.new(config: config)
    Uploadcare::Result.unwrap(file_metadata_client.delete(uuid: uuid, key: key, request_options: request_options))
  end
end

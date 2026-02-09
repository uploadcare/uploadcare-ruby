# frozen_string_literal: true

# Client for file metadata operations.
require 'uri'
class Uploadcare::FileMetadataClient < Uploadcare::RestClient
  # Retrieves all metadata associated with a specific file by UUID.
  # @param uuid [String] The UUID of the file.
  # @return [Hash] A hash containing all metadata key-value pairs for the file.
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/_fileMetadata
  def index(uuid:, request_options: {})
    encoded_uuid = URI.encode_www_form_component(uuid)
    get(path: "/files/#{encoded_uuid}/metadata/", params: {}, headers: {}, request_options: request_options)
  end

  # Gets the value of a specific metadata key for a file by UUID
  # @param uuid [String] The UUID of the file
  # @param key [String] The metadata key
  # @return [String] The value of the metadata key
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/fileMetadata
  def show(uuid:, key:, request_options: {})
    encoded_uuid = URI.encode_www_form_component(uuid)
    encoded_key = URI.encode_www_form_component(key)
    get(path: "/files/#{encoded_uuid}/metadata/#{encoded_key}/", params: {}, headers: {}, request_options: request_options)
  end

  # Updates or creates a metadata key for a specific file by UUID
  # @param uuid [String] The UUID of the file
  # @param key [String] The key of the metadata
  # @param value [String] The value of the metadata
  # @return [String] The value of the updated or added metadata key
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/updateFileMetadataKey
  def update(uuid:, key:, value:, request_options: {})
    encoded_uuid = URI.encode_www_form_component(uuid)
    encoded_key = URI.encode_www_form_component(key)
    put(path: "/files/#{encoded_uuid}/metadata/#{encoded_key}/", params: value, headers: {}, request_options: request_options)
  end

  # Deletes a specific metadata key for a file by UUID
  # @param uuid [String] The UUID of the file
  # @param key [String] The metadata key to delete
  # @return [Nil] Returns nil on successful deletion
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/deleteFileMetadata
  def delete(uuid:, key:, request_options: {})
    encoded_uuid = URI.encode_www_form_component(uuid)
    encoded_key = URI.encode_www_form_component(key)
    super(path: "/files/#{encoded_uuid}/metadata/#{encoded_key}/", params: {}, headers: {}, request_options: request_options)
  end
end

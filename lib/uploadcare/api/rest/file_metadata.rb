# frozen_string_literal: true

require 'uri'

# REST API endpoint for file metadata operations.
#
# @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata
class Uploadcare::Api::Rest::FileMetadata
  # @return [Uploadcare::Api::Rest] Parent REST client
  attr_reader :rest

  # @param rest [Uploadcare::Api::Rest] Parent REST client
  def initialize(rest:)
    @rest = rest
  end

  # Get all metadata for a file.
  #
  # @param uuid [String] File UUID
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result] Hash of metadata key-value pairs
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/_fileMetadata
  def index(uuid:, request_options: {})
    encoded_uuid = URI.encode_www_form_component(uuid)
    rest.get(path: "/files/#{encoded_uuid}/metadata/", params: {}, headers: {},
             request_options: request_options)
  end

  # Get the value of a specific metadata key.
  #
  # @param uuid [String] File UUID
  # @param key [String] Metadata key
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result] Metadata value
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/fileMetadata
  def show(uuid:, key:, request_options: {})
    encoded_uuid = URI.encode_www_form_component(uuid)
    encoded_key = URI.encode_www_form_component(key)
    rest.get(path: "/files/#{encoded_uuid}/metadata/#{encoded_key}/", params: {}, headers: {},
             request_options: request_options)
  end

  # Update or create a metadata key for a file.
  #
  # @param uuid [String] File UUID
  # @param key [String] Metadata key
  # @param value [String] Metadata value
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result] Updated value
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/updateFileMetadataKey
  def update(uuid:, key:, value:, request_options: {})
    encoded_uuid = URI.encode_www_form_component(uuid)
    encoded_key = URI.encode_www_form_component(key)
    rest.put(path: "/files/#{encoded_uuid}/metadata/#{encoded_key}/", params: value.to_json, headers: {},
             request_options: request_options)
  end

  # Delete a metadata key for a file.
  #
  # @param uuid [String] File UUID
  # @param key [String] Metadata key to delete
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result]
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata/operation/deleteFileMetadata
  def delete(uuid:, key:, request_options: {})
    encoded_uuid = URI.encode_www_form_component(uuid)
    encoded_key = URI.encode_www_form_component(key)
    rest.request(method: :delete, path: "/files/#{encoded_uuid}/metadata/#{encoded_key}/",
                 params: {}, headers: {}, request_options: request_options)
  end
end

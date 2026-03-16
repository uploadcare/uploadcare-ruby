# frozen_string_literal: true

# File metadata resource for managing key-value metadata on files.
#
# @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-metadata
class Uploadcare::Resources::FileMetadata < Uploadcare::Resources::BaseResource
  def initialize(attributes = {}, client_or_config = nil)
    super
    @metadata = {}
  end

  # --- Instance methods ---

  # Retrieve all metadata for the file.
  #
  # @param uuid [String, nil] File UUID (defaults to instance UUID)
  # @param request_options [Hash] Request options
  # @return [self]
  def index(uuid: nil, request_options: {})
    response = Uploadcare::Result.unwrap(
      client.api.rest.file_metadata.index(uuid: uuid || @uuid, request_options: request_options)
    )
    @metadata = response if response.is_a?(Hash)
    self
  end

  # Access a metadata value by key.
  #
  # @param key [String, Symbol] Metadata key
  # @return [String, nil] Metadata value
  def [](key)
    @metadata[key.to_s]
  end

  # Set a metadata value by key (local only, call #update to persist).
  #
  # @param key [String, Symbol] Metadata key
  # @param value [String] Metadata value
  def []=(key, value)
    @metadata[key.to_s] = value
  end

  # Return all metadata as a hash.
  #
  # @return [Hash]
  def to_h
    @metadata.dup
  end

  # Update a metadata key's value on the server.
  #
  # @param key [String] Metadata key
  # @param value [String] Metadata value
  # @param uuid [String, nil] File UUID (defaults to instance UUID)
  # @param request_options [Hash] Request options
  # @return [String] The updated value
  def update(key:, value:, uuid: nil, request_options: {})
    target_uuid = uuid || @uuid
    result = Uploadcare::Result.unwrap(
      client.api.rest.file_metadata.update(
        uuid: target_uuid, key: key, value: value, request_options: request_options
      )
    )
    @metadata[key.to_s] = result if target_uuid == @uuid
    result
  end

  # Retrieve a single metadata key's value.
  #
  # @param key [String] Metadata key
  # @param uuid [String, nil] File UUID (defaults to instance UUID)
  # @param request_options [Hash] Request options
  # @return [String] Metadata value
  def show(key:, uuid: nil, request_options: {})
    Uploadcare::Result.unwrap(
      client.api.rest.file_metadata.show(uuid: uuid || @uuid, key: key, request_options: request_options)
    )
  end

  # Delete a metadata key.
  #
  # @param key [String] Metadata key
  # @param uuid [String, nil] File UUID (defaults to instance UUID)
  # @param request_options [Hash] Request options
  # @return [nil]
  def delete(key:, uuid: nil, request_options: {})
    target_uuid = uuid || @uuid
    result = Uploadcare::Result.unwrap(
      client.api.rest.file_metadata.delete(uuid: target_uuid, key: key, request_options: request_options)
    )
    @metadata.delete(key.to_s) if target_uuid == @uuid
    result
  end

  # --- Class methods ---

  # Get all metadata for a file.
  def self.index(uuid:, client: nil, config: Uploadcare.configuration, request_options: {})
    resolved_client = resolve_client(client: client, config: config)
    Uploadcare::Result.unwrap(
      resolved_client.api.rest.file_metadata.index(uuid: uuid, request_options: request_options)
    )
  end

  # Get a single metadata key's value.
  def self.show(uuid:, key:, client: nil, config: Uploadcare.configuration, request_options: {})
    resolved_client = resolve_client(client: client, config: config)
    Uploadcare::Result.unwrap(
      resolved_client.api.rest.file_metadata.show(uuid: uuid, key: key, request_options: request_options)
    )
  end

  # Update a metadata key's value.
  def self.update(uuid:, key:, value:, client: nil, config: Uploadcare.configuration, request_options: {})
    resolved_client = resolve_client(client: client, config: config)
    Uploadcare::Result.unwrap(
      resolved_client.api.rest.file_metadata.update(
        uuid: uuid, key: key, value: value, request_options: request_options
      )
    )
  end

  # Delete a metadata key.
  def self.delete(uuid:, key:, client: nil, config: Uploadcare.configuration, request_options: {})
    resolved_client = resolve_client(client: client, config: config)
    Uploadcare::Result.unwrap(
      resolved_client.api.rest.file_metadata.delete(uuid: uuid, key: key, request_options: request_options)
    )
  end
end

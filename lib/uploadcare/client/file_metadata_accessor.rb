# frozen_string_literal: true

# File metadata operations scoped to a client instance.
class Uploadcare::Client::FileMetadataAccessor
  attr_reader :client

  # @param client [Uploadcare::Client]
  def initialize(client:)
    @client = client
  end

  # @param uuid [String]
  # @param request_options [Hash]
  # @return [Uploadcare::Resources::FileMetadata]
  def index(uuid:, request_options: {})
    Uploadcare::Resources::FileMetadata.index(uuid: uuid, client: client, request_options: request_options)
  end

  # @param uuid [String]
  # @param key [String]
  # @param request_options [Hash]
  # @return [String, nil]
  def show(uuid:, key:, request_options: {})
    Uploadcare::Resources::FileMetadata.show(uuid: uuid, key: key, client: client,
                                             request_options: request_options)
  end

  # @param uuid [String]
  # @param key [String]
  # @param value [String]
  # @param request_options [Hash]
  # @return [Uploadcare::Resources::FileMetadata]
  def update(uuid:, key:, value:, request_options: {})
    Uploadcare::Resources::FileMetadata.update(uuid: uuid, key: key, value: value, client: client,
                                               request_options: request_options)
  end

  # @param uuid [String]
  # @param key [String]
  # @param request_options [Hash]
  # @return [nil]
  def delete(uuid:, key:, request_options: {})
    Uploadcare::Resources::FileMetadata.delete(uuid: uuid, key: key, client: client,
                                               request_options: request_options)
  end
end

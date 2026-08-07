# frozen_string_literal: true

# Resource for reading and changing the ordered tag list associated with a file.
#
# @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/File-tags
class Uploadcare::Resources::FileTags < Uploadcare::Resources::BaseResource
  attr_accessor :uuid, :tags, :added, :deleted

  def initialize(attributes = {}, client_or_config = nil)
    @tags = []
    @added = []
    @deleted = []
    super
  end

  # Fetch the current tags.
  #
  # @param request_options [Hash] Request options
  # @return [self]
  def list(request_options: {})
    response = Uploadcare::Result.unwrap(
      client.api.rest.file_tags.list(uuid: uuid, request_options: request_options)
    )
    self.tags = response.fetch('tags', [])
    self.added = []
    self.deleted = []
    self
  end
  alias index list

  # Replace the complete tag list. An empty array clears all tags.
  #
  # @param tags [Array<String>]
  # @param request_options [Hash] Request options
  # @return [self]
  def replace(tags:, request_options: {})
    normalized = Uploadcare::Internal::FileTagNormalizer.call(tags)
    response = Uploadcare::Result.unwrap(
      client.api.rest.file_tags.replace(uuid: uuid, tags: normalized, request_options: request_options)
    )
    assign_attributes(response)
    self
  end

  # Atomically add and delete tags. Deletions are applied first.
  #
  # @param add [Array<String>] Tags to add
  # @param delete [Array<String>] Tags to delete
  # @param request_options [Hash] Request options
  # @return [self]
  def update(add: [], delete: [], request_options: {})
    normalized_add = Uploadcare::Internal::FileTagNormalizer.call(add)
    normalized_delete = Uploadcare::Internal::FileTagNormalizer.call(delete, max_count: nil)
    response = Uploadcare::Result.unwrap(
      client.api.rest.file_tags.update(
        uuid: uuid, add: normalized_add, delete: normalized_delete, request_options: request_options
      )
    )
    assign_attributes(response)
    self
  end

  # Get the current tag list for a file.
  #
  # @return [Array<String>]
  def self.list(uuid:, client: nil, config: Uploadcare.configuration, request_options: {})
    resolved_client = resolve_client(client: client, config: config)
    new({ uuid: uuid }, resolved_client).list(request_options: request_options).tags.dup
  end

  class << self
    alias index list
  end

  # Replace the complete tag list for a file.
  #
  # @return [Uploadcare::Resources::FileTags]
  def self.replace(uuid:, tags:, client: nil, config: Uploadcare.configuration, request_options: {})
    resolved_client = resolve_client(client: client, config: config)
    new({ uuid: uuid }, resolved_client).replace(tags: tags, request_options: request_options)
  end

  # Atomically add and delete tags for a file.
  #
  # @return [Uploadcare::Resources::FileTags]
  def self.update(uuid:, add: [], delete: [], client: nil, config: Uploadcare.configuration, request_options: {})
    resolved_client = resolve_client(client: client, config: config)
    new({ uuid: uuid }, resolved_client).update(
      add: add, delete: delete, request_options: request_options
    )
  end
end

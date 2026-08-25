# frozen_string_literal: true

# Per-file tag operations scoped to a client instance.
#
# @example Replace and update tags
#   client.file_tags.replace(uuid: file.uuid, tags: %w[approved summer])
#   client.file_tags.update(uuid: file.uuid, add: ["featured"], delete: ["summer"])
class Uploadcare::Client::FileTagsAccessor
  attr_reader :client

  # @param client [Uploadcare::Client]
  def initialize(client:)
    @client = client
  end

  # @param uuid [String]
  # @param request_options [Hash]
  # @return [Array<String>]
  def list(uuid:, request_options: {})
    Uploadcare::Resources::FileTags.list(uuid: uuid, client: client, request_options: request_options)
  end
  alias index list

  # @param uuid [String]
  # @param tags [Array<String>]
  # @param request_options [Hash]
  # @return [Uploadcare::Resources::FileTags]
  def replace(uuid:, tags:, request_options: {})
    Uploadcare::Resources::FileTags.replace(
      uuid: uuid, tags: tags, client: client, request_options: request_options
    )
  end

  # @param uuid [String]
  # @param add [Array<String>]
  # @param delete [Array<String>]
  # @param request_options [Hash]
  # @return [Uploadcare::Resources::FileTags]
  def update(uuid:, add: [], delete: [], request_options: {})
    Uploadcare::Resources::FileTags.update(
      uuid: uuid, add: add, delete: delete, client: client, request_options: request_options
    )
  end
end

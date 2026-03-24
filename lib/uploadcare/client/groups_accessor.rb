# frozen_string_literal: true

# High-level group operations scoped to a client instance.
class Uploadcare::Client::GroupsAccessor
  attr_reader :client

  # @param client [Uploadcare::Client]
  def initialize(client:)
    @client = client
  end

  # @param uuids [Array<String>]
  # @param request_options [Hash]
  # @param options [Hash]
  # @return [Uploadcare::Resources::Group]
  def create(uuids:, request_options: {}, **options)
    Uploadcare::Resources::Group.create(
      uuids: uuids, client: client, request_options: request_options, **options
    )
  end

  # @param group_id [String]
  # @param request_options [Hash]
  # @return [Uploadcare::Resources::Group]
  def find(group_id:, request_options: {})
    Uploadcare::Resources::Group.find(group_id: group_id, client: client, request_options: request_options)
  end

  # @param request_options [Hash]
  # @param params [Hash]
  # @return [Uploadcare::Collections::Paginated]
  def list(request_options: {}, **params)
    Uploadcare::Resources::Group.list(params: params, client: client, request_options: request_options)
  end
end

# frozen_string_literal: true

# High-level file operations scoped to a client instance.
class Uploadcare::Client::FilesAccessor
  attr_reader :client

  # @param client [Uploadcare::Client]
  def initialize(client:)
    @client = client
  end

  # @param uuid [String]
  # @param params [Hash]
  # @param request_options [Hash]
  # @return [Uploadcare::Resources::File]
  def find(uuid:, params: {}, request_options: {})
    Uploadcare::Resources::File.find(
      uuid: uuid, params: params, client: client, request_options: request_options
    )
  end

  # @param request_options [Hash]
  # @param options [Hash]
  # @return [Uploadcare::Collections::Paginated]
  def list(request_options: {}, **options)
    Uploadcare::Resources::File.list(
      options: options, client: client, request_options: request_options
    )
  end

  # @param source [IO, Array<IO>, String]
  # @param request_options [Hash]
  # @param options [Hash]
  # @yield [Hash]
  # @return [Uploadcare::Resources::File, Array<Uploadcare::Resources::File>, Hash]
  def upload(source, request_options: {}, **options, &block)
    client.uploads.upload(source, request_options: request_options, **options, &block)
  end

  # @param url [String]
  # @param request_options [Hash]
  # @param options [Hash]
  # @return [Uploadcare::Resources::File, Hash]
  def upload_from_url(url, request_options: {}, **options)
    client.uploads.upload_from_url(url: url, request_options: request_options, **options)
  end

  # @param uuids [Array<String>]
  # @param request_options [Hash]
  # @return [Uploadcare::BatchResult]
  def batch_store(uuids:, request_options: {})
    Uploadcare::Resources::File.batch_store(uuids: uuids, client: client, request_options: request_options)
  end

  # @param uuids [Array<String>]
  # @param request_options [Hash]
  # @return [Uploadcare::BatchResult]
  def batch_delete(uuids:, request_options: {})
    Uploadcare::Resources::File.batch_delete(uuids: uuids, client: client, request_options: request_options)
  end

  # @param source [String]
  # @param options [Hash]
  # @param request_options [Hash]
  # @return [Uploadcare::Resources::File]
  def copy_to_local(source:, options: {}, request_options: {})
    Uploadcare::Resources::File.local_copy(
      source: source, options: options, client: client, request_options: request_options
    )
  end

  # @param source [String]
  # @param target [String]
  # @param options [Hash]
  # @param request_options [Hash]
  # @return [Hash]
  def copy_to_remote(source:, target:, options: {}, request_options: {})
    Uploadcare::Resources::File.remote_copy(
      source: source, target: target, options: options, client: client, request_options: request_options
    )
  end
end

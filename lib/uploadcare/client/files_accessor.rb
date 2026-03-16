# frozen_string_literal: true

class Uploadcare::Client::FilesAccessor
  attr_reader :client

  def initialize(client:)
    @client = client
  end

  def find(uuid:, params: {}, request_options: {})
    Uploadcare::Resources::File.find(
      uuid: uuid, params: params, client: client, request_options: request_options
    )
  end

  def list(request_options: {}, **options)
    Uploadcare::Resources::File.list(
      options: options, client: client, request_options: request_options
    )
  end

  def upload(source, request_options: {}, **options, &block)
    client.uploads.upload(source, request_options: request_options, **options, &block)
  end

  def upload_from_url(url, request_options: {}, **options)
    client.uploads.upload_from_url(url: url, request_options: request_options, **options)
  end

  def batch_store(uuids:, request_options: {})
    Uploadcare::Resources::File.batch_store(uuids: uuids, client: client, request_options: request_options)
  end

  def batch_delete(uuids:, request_options: {})
    Uploadcare::Resources::File.batch_delete(uuids: uuids, client: client, request_options: request_options)
  end

  def copy_to_local(source:, options: {}, request_options: {})
    Uploadcare::Resources::File.local_copy(
      source: source, options: options, client: client, request_options: request_options
    )
  end

  def copy_to_remote(source:, target:, options: {}, request_options: {})
    Uploadcare::Resources::File.remote_copy(
      source: source, target: target, options: options, client: client, request_options: request_options
    )
  end
end

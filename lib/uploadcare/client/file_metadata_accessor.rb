# frozen_string_literal: true

class Uploadcare::Client::FileMetadataAccessor
  attr_reader :client

  def initialize(client:)
    @client = client
  end

  def index(uuid:, request_options: {})
    Uploadcare::Resources::FileMetadata.index(uuid: uuid, client: client, request_options: request_options)
  end

  def show(uuid:, key:, request_options: {})
    Uploadcare::Resources::FileMetadata.show(uuid: uuid, key: key, client: client,
                                             request_options: request_options)
  end

  def update(uuid:, key:, value:, request_options: {})
    Uploadcare::Resources::FileMetadata.update(uuid: uuid, key: key, value: value, client: client,
                                               request_options: request_options)
  end

  def delete(uuid:, key:, request_options: {})
    Uploadcare::Resources::FileMetadata.delete(uuid: uuid, key: key, client: client,
                                               request_options: request_options)
  end
end

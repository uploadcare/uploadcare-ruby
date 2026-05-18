# frozen_string_literal: true

# High-level document conversion helpers scoped to a client instance.
class Uploadcare::Client::DocumentConversionsAccessor
  attr_reader :client

  # @param client [Uploadcare::Client]
  def initialize(client:)
    @client = client
  end

  # @param uuid [String]
  # @param format [String, Symbol]
  # @param options [Hash]
  # @param request_options [Hash]
  # @return [Hash]
  def convert(uuid:, format:, options: {}, request_options: {})
    Uploadcare::Resources::DocumentConversion.convert_document(
      params: { uuid: uuid, format: format }, options: options, client: client,
      request_options: request_options
    )
  end

  # @param token [String]
  # @param request_options [Hash]
  # @return [Uploadcare::Resources::DocumentConversion]
  def status(token:, request_options: {})
    Uploadcare::Resources::DocumentConversion.status(
      token: token, client: client, request_options: request_options
    )
  end

  # @param uuid [String]
  # @param request_options [Hash]
  # @return [Uploadcare::Resources::DocumentConversion]
  def info(uuid:, request_options: {})
    Uploadcare::Resources::DocumentConversion.info_for(
      uuid: uuid, client: client, request_options: request_options
    )
  end
end

# frozen_string_literal: true

# High-level video conversion helpers scoped to a client instance.
class Uploadcare::Client::VideoConversionsAccessor
  attr_reader :client

  # @param client [Uploadcare::Client]
  def initialize(client:)
    @client = client
  end

  # @param uuid [String]
  # @param format [String, Symbol]
  # @param quality [String, Symbol]
  # @param options [Hash]
  # @param request_options [Hash]
  # @return [Uploadcare::Resources::VideoConversion]
  def convert(uuid:, format:, quality:, options: {}, request_options: {})
    Uploadcare::Resources::VideoConversion.convert(
      params: { uuid: uuid, format: format, quality: quality }, options: options, client: client,
      request_options: request_options
    )
  end

  # @param token [String]
  # @param request_options [Hash]
  # @return [Uploadcare::Resources::VideoConversion]
  def status(token:, request_options: {})
    Uploadcare::Resources::VideoConversion.status(
      token: token, client: client, request_options: request_options
    )
  end
end

# frozen_string_literal: true

# High-level webhook operations scoped to a client instance.
class Uploadcare::Client::WebhooksAccessor
  attr_reader :client

  # @param client [Uploadcare::Client]
  def initialize(client:)
    @client = client
  end

  # @param request_options [Hash]
  # @return [Array<Uploadcare::Resources::Webhook>]
  def list(request_options: {})
    Uploadcare::Resources::Webhook.list(client: client, request_options: request_options)
  end

  # @param target_url [String]
  # @param request_options [Hash]
  # @param options [Hash]
  # @return [Uploadcare::Resources::Webhook]
  def create(target_url:, request_options: {}, **options)
    Uploadcare::Resources::Webhook.create(
      target_url: target_url, client: client, request_options: request_options, **options
    )
  end

  # @param id [String]
  # @param request_options [Hash]
  # @param options [Hash]
  # @return [Uploadcare::Resources::Webhook]
  def update(id:, request_options: {}, **options)
    Uploadcare::Resources::Webhook.update(id: id, client: client, request_options: request_options, **options)
  end

  # @param target_url [String]
  # @param request_options [Hash]
  # @return [nil]
  def delete(target_url:, request_options: {})
    Uploadcare::Resources::Webhook.delete(target_url: target_url, client: client, request_options: request_options)
  end
end

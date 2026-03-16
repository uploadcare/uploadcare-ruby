# frozen_string_literal: true

class Uploadcare::Client::WebhooksAccessor
  attr_reader :client

  def initialize(client:)
    @client = client
  end

  def list(request_options: {})
    Uploadcare::Resources::Webhook.list(client: client, request_options: request_options)
  end

  def create(target_url:, request_options: {}, **options)
    Uploadcare::Resources::Webhook.create(
      target_url: target_url, client: client, request_options: request_options, **options
    )
  end

  def update(id:, request_options: {}, **options)
    Uploadcare::Resources::Webhook.update(id: id, client: client, request_options: request_options, **options)
  end

  def delete(target_url:, request_options: {})
    Uploadcare::Resources::Webhook.delete(target_url: target_url, client: client, request_options: request_options)
  end
end

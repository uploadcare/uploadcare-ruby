# frozen_string_literal: true

module Uploadcare
  class Webhook < BaseResource
    attr_accessor :id, :project, :created, :updated, :event, :target_url, :is_active, :signing_secret, :version

    def initialize(attributes = {}, config = Uploadcare.configuration)
      super
    end

    # Class method to list all project webhooks
    # @return [Array<Uploadcare::Webhook>] Array of Webhook instances
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook/operation/webhooksList
    def self.list(config = Uploadcare.configuration)
      webhook_client = Uploadcare::WebhookClient.new(config)
      response = webhook_client.list_webhooks

      response.map { |webhook_data| new(webhook_data, config) }
    end

    # Create a new webhook
    # @param target_url [String] The URL triggered by the webhook event
    # @param event [String] The event to subscribe to
    # @param is_active [Boolean] Marks subscription as active or inactive
    # @param signing_secret [String] HMAC/SHA-256 secret for securing webhook payloads
    # @param version [String] Version of the webhook payload
    # @return [Uploadcare::Webhook] The created webhook as an object
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook/operation/webhookCreate

    def self.create(target_url, event, is_active: true, signing_secret: nil, version: '0.7')
      client = Uploadcare::WebhookClient.new
      response = client.create_webhook(target_url, event, is_active, signing_secret, version)
      new(response)
    end

    # Update a webhook
    # @param id [Integer] The ID of the webhook to update
    # @param target_url [String] The new target URL
    # @param event [String] The new event type
    # @param is_active [Boolean] Whether the webhook is active
    # @param signing_secret [String] Optional signing secret for the webhook
    # @return [Uploadcare::Webhook] The updated webhook as an object
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook/operation/updateWebhook
    def self.update(id, target_url, event, is_active: true, signing_secret: nil)
      client = Uploadcare::WebhookClient.new
      response = client.update_webhook(id, target_url, event, is_active: is_active, signing_secret: signing_secret)
      new(response)
    end

    # Delete a webhook
    # @param target_url [String] The target URL of the webhook to delete
    # @return nil on successful deletion
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook/operation/webhookUnsubscribe

    def self.delete(target_url)
      client = Uploadcare::WebhookClient.new
      client.delete_webhook(target_url)
    end
  end
end

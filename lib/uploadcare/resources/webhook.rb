# frozen_string_literal: true

module Uploadcare
  class Webhook < BaseResource
    attr_accessor :id, :project, :created, :updated, :event, :target_url, :is_active, :signing_secret, :version

    # Class method to list all project webhooks
    # @return [Array<Uploadcare::Webhook>] Array of Webhook instances
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook/operation/webhooksList
    def self.list(config: Uploadcare.configuration, request_options: {})
      response = Uploadcare::Result.unwrap(webhook_client(config).list_webhooks(request_options: request_options))

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
    def self.create(target_url:, config: Uploadcare.configuration, request_options: {}, **options)
      event = options.fetch(:event, 'file.uploaded')
      is_active = options.key?(:is_active) ? options[:is_active] : true
      signing_secret = options[:signing_secret]
      version = options[:version]
      payload = {
        target_url: target_url,
        event: event,
        is_active: is_active
      }
      payload[:signing_secret] = signing_secret if signing_secret
      payload[:version] = version if version

      response = Uploadcare::Result.unwrap(
        webhook_client(config).create_webhook(options: payload, request_options: request_options)
      )
      new(response, config)
    end

    # Update a webhook
    # @param id [Integer] The ID of the webhook to update
    # @param target_url [String] The new target URL
    # @param event [String] The new event type
    # @param is_active [Boolean] Whether the webhook is active
    # @param signing_secret [String] Optional signing secret for the webhook
    # @return [Uploadcare::Webhook] The updated webhook as an object
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook/operation/updateWebhook
    def self.update(id:, config: Uploadcare.configuration, request_options: {}, **options)
      payload = update_payload(options)

      response = Uploadcare::Result.unwrap(
        webhook_client(config).update_webhook(id: id, options: payload, request_options: request_options)
      )
      new(response, config)
    end

    # Delete a webhook
    # @param target_url [String] The target URL of the webhook to delete
    # @return nil on successful deletion
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook/operation/webhookUnsubscribe

    def self.delete(target_url:, config: Uploadcare.configuration, request_options: {})
      Uploadcare::Result.unwrap(
        webhook_client(config).delete_webhook(target_url: target_url, request_options: request_options)
      )
    end

    def self.update_payload(options)
      payload = options.slice(:target_url, :event, :signing_secret, :version)
      payload[:is_active] = options[:is_active] if options.key?(:is_active)
      payload
    end
    private_class_method :update_payload

    def self.webhook_client(config)
      @webhook_clients ||= {}
      @webhook_clients[config] ||= Uploadcare::WebhookClient.new(config: config)
    end
    private_class_method :webhook_client
  end
end

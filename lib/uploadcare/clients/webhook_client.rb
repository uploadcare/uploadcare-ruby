# frozen_string_literal: true

module Uploadcare
  class WebhookClient < RestClient
    # Fetches a list of project webhooks
    # @return [Array<Hash>] List of webhooks for the project
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook/operation/webhooksList
    def list_webhooks(request_options: {})
      get(path: '/webhooks/', params: {}, headers: {}, request_options: request_options)
    end

    # Create a new webhook
    # @param target_url [String] The URL triggered by the webhook event
    # @param event [String] The event to subscribe to (e.g., "file.uploaded")
    # @param is_active [Boolean] Marks subscription as active or inactive
    # @param signing_secret [String] HMAC/SHA-256 secret for securing webhook payloads
    # @param version [String] Version of the webhook payload
    # @return [Uploadcare::Webhook] The created webhook as an object
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook/operation/webhookCreate
    def create_webhook(options: {}, request_options: {})
      payload = {
        target_url: options[:target_url],
        event: options[:event] || 'file.uploaded',
        is_active: options[:is_active].nil? || options[:is_active]
      }

      # Add signing_secret if provided
      payload.merge!({ signing_secret: options[:signing_secret] }.compact)

      post(path: '/webhooks/', params: payload, headers: {}, request_options: request_options)
    end

    # Update a webhook
    # @param id [Integer] The ID of the webhook to update
    # @param target_url [String] The new target URL
    # @param event [String] The new event type
    # @param is_active [Boolean] Whether the webhook is active
    # @param signing_secret [String] Optional signing secret for the webhook
    # @return [Hash] The updated webhook attributes
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook/operation/updateWebhook
    def update_webhook(id:, options: {}, request_options: {})
      put(path: "/webhooks/#{id}/", params: options, headers: {}, request_options: request_options)
    end

    # Delete a webhook
    # @param target_url [String] The target URL of the webhook to delete
    # @return [Nil] Returns nil on successful deletion of the webhook.
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook/operation/webhookUnsubscribe
    def delete_webhook(target_url:, request_options: {})
      payload = { target_url: target_url }
      # Call parent class delete method directly
      RestClient.instance_method(:delete).bind(self).call(path: '/webhooks/unsubscribe/', params: payload, headers: {},
                                                          request_options: request_options)
    end
  end
end

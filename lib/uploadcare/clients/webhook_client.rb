# frozen_string_literal: true

module Uploadcare
  class WebhookClient < RestClient
    # Fetches a list of project webhooks
    # @return [Array<Hash>] List of webhooks for the project
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook/operation/webhooksList
    def list_webhooks
      get('/webhooks/')
    end

    # Create a new webhook
    # @param target_url [String] The URL triggered by the webhook event
    # @param event [String] The event to subscribe to (e.g., "file.uploaded")
    # @param is_active [Boolean] Marks subscription as active or inactive
    # @param signing_secret [String] HMAC/SHA-256 secret for securing webhook payloads
    # @param version [String] Version of the webhook payload
    # @return [Uploadcare::Webhook] The created webhook as an object
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook/operation/webhookCreate
    def create_webhook(target_url, event, is_active, signing_secret, version)
      payload = {
        target_url: target_url,
        event: event,
        is_active: is_active,
        signing_secret: signing_secret,
        version: version
      }

      post('/webhooks/', payload)
    end

    # Update a webhook
    # @param id [Integer] The ID of the webhook to update
    # @param target_url [String] The new target URL
    # @param event [String] The new event type
    # @param is_active [Boolean] Whether the webhook is active
    # @param signing_secret [String] Optional signing secret for the webhook
    # @return [Hash] The updated webhook attributes
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook/operation/updateWebhook
    def update_webhook(id, target_url, event, is_active: true, signing_secret: nil)
      payload = {
        target_url: target_url,
        event: event,
        is_active: is_active,
        signing_secret: signing_secret
      }

      put("/webhooks/#{id}/", payload)
    end

    # Delete a webhook
    # @param target_url [String] The target URL of the webhook to delete
    # @return [Nil] Returns nil on successful deletion of the webhook.
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook/operation/webhookUnsubscribe
    def delete_webhook(target_url)
      del('/webhooks/unsubscribe/', target_url)
    end
  end
end

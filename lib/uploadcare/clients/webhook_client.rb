# frozen_string_literal: true

# Client for webhook operations.
class Uploadcare::WebhookClient < Uploadcare::RestClient
  # Fetches a list of project webhooks
  # @return [Array<Hash>] List of webhooks for the project
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook/operation/webhooksList
  def list_webhooks(request_options: {})
    get(path: '/webhooks/', params: {}, headers: {}, request_options: request_options)
  end

  # Create a new webhook.
  #
  # @param options [Hash] webhook options
  # @option options [String] :target_url webhook target URL
  # @option options [String] :event event type (default: "file.uploaded")
  # @option options [Boolean] :is_active active flag
  # @option options [String] :signing_secret signing secret
  # @option options [String] :version webhook payload version
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

  # Update a webhook.
  #
  # @param id [Integer] webhook ID
  # @param options [Hash] webhook options
  # @option options [String] :target_url webhook target URL
  # @option options [String] :event event type
  # @option options [Boolean] :is_active active flag
  # @option options [String] :signing_secret signing secret
  # @option options [String] :version webhook payload version
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
    Uploadcare::RestClient.instance_method(:delete).bind(self).call(path: '/webhooks/unsubscribe/', params: payload,
                                                                    headers: {}, request_options: request_options)
  end
end

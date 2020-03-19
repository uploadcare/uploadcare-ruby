# frozen_string_literal: true

require_relative 'rest_client'

module Uploadcare
  module Client
    # client for webhook management
    # @see https://uploadcare.com/api-refs/rest-api/v0.5.0/#tag/Webhook
    class WebhookClient < RestClient
      # Create webhook
      # @see https://uploadcare.com/docs/api_reference/rest/webhooks/#subscribe
      def create(target_url, event: 'file.uploaded', is_active: true)
        body = { 'target_url': target_url, 'event': event, 'is_active': is_active }.to_json
        post(uri: '/webhooks/', content: body)
      end

      # Returns array (not paginated list) of webhooks
      # @see https://uploadcare.com/docs/api_reference/rest/webhooks/#get-list
      def list
        get(uri: '/webhooks/')
      end

      # Permanently deletes subscription
      # @see https://uploadcare.com/docs/api_reference/rest/webhooks/#unsubscribe
      def delete(name)
        body = { 'name': name }.to_json
        post(uri: '/webhooks/unsubscribe/', content: body)
      end

      # Updates webhook
      # @see https://uploadcare.com/docs/api_reference/rest/webhooks/#subscribe-update
      def update(id, **options)
        body = options.to_json
        post(uri: "/webhooks/#{id}/", content: body)
      end

      alias create_webhook create
      alias list_webhooks list
      alias delete_webhook delete
      alias update_webhook update
    end
  end
end

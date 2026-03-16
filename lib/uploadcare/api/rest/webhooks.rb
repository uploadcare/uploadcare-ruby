# frozen_string_literal: true

# REST API endpoint for webhook operations.
#
# @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook
module Uploadcare
  module Api
    class Rest
      class Webhooks
        # @return [Uploadcare::Api::Rest] Parent REST client
        attr_reader :rest

        # @param rest [Uploadcare::Api::Rest] Parent REST client
        def initialize(rest:)
          @rest = rest
        end

        # List all project webhooks.
        #
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Array of webhook hashes
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook/operation/webhooksList
        def list(request_options: {})
          rest.get(path: '/webhooks/', params: {}, headers: {}, request_options: request_options)
        end

        # Create a new webhook.
        #
        # @param options [Hash] Webhook options
        # @option options [String] :target_url Webhook target URL (required)
        # @option options [String] :event Event type (default: "file.uploaded")
        # @option options [Boolean] :is_active Active flag (default: true)
        # @option options [String] :signing_secret Signing secret
        # @option options [String] :version Webhook payload version
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Created webhook attributes
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook/operation/webhookCreate
        def create(options: {}, request_options: {})
          payload = {
            target_url: options[:target_url],
            event: options[:event] || 'file.uploaded',
            is_active: options[:is_active].nil? || options[:is_active]
          }
          payload.merge!({ signing_secret: options[:signing_secret] }.compact)
          payload.merge!({ version: options[:version] }.compact)

          rest.post(path: '/webhooks/', params: payload, headers: {}, request_options: request_options)
        end

        # Update a webhook.
        #
        # @param id [Integer] Webhook ID
        # @param options [Hash] Webhook options to update
        # @option options [String] :target_url Target URL
        # @option options [String] :event Event type
        # @option options [Boolean] :is_active Active flag
        # @option options [String] :signing_secret Signing secret
        # @option options [String] :version Webhook payload version
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result] Updated webhook attributes
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook/operation/updateWebhook
        def update(id:, options: {}, request_options: {})
          rest.put(path: "/webhooks/#{id}/", params: options, headers: {}, request_options: request_options)
        end

        # Delete a webhook by target URL.
        #
        # @param target_url [String] Target URL of the webhook to delete
        # @param request_options [Hash] Request options
        # @return [Uploadcare::Result]
        # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook/operation/webhookUnsubscribe
        def delete(target_url:, request_options: {})
          payload = { target_url: target_url }
          rest.request(method: :delete, path: '/webhooks/unsubscribe/', params: payload, headers: {},
                       request_options: request_options)
        end
      end
    end
  end
end

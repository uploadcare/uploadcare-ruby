# frozen_string_literal: true

# Webhook resource for managing Uploadcare webhooks.
#
# @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Webhook
module Uploadcare
  module Resources
    class Webhook < BaseResource
      attr_accessor :id, :project, :created, :updated, :event, :target_url, :is_active, :signing_secret, :version

      # List all project webhooks.
      #
      # @param client [Uploadcare::Client, nil] Client instance
      # @param config [Uploadcare::Configuration] Configuration fallback
      # @param request_options [Hash] Request options
      # @return [Array<Uploadcare::Resources::Webhook>]
      def self.list(client: nil, config: Uploadcare.configuration, request_options: {})
        resolved_client = resolve_client(client: client, config: config)
        response = Uploadcare::Result.unwrap(
          resolved_client.api.rest.webhooks.list(request_options: request_options)
        )
        response.map { |data| new(data, resolved_client) }
      end

      # Create a new webhook.
      #
      # @param target_url [String] Webhook target URL
      # @param options [Hash] Webhook options
      # @option options [String] :event Event type (default: "file.uploaded")
      # @option options [Boolean] :is_active Active flag (default: true)
      # @option options [String] :signing_secret Signing secret
      # @option options [String] :version Webhook payload version
      # @param client [Uploadcare::Client, nil] Client instance
      # @param config [Uploadcare::Configuration] Configuration fallback
      # @param request_options [Hash] Request options
      # @return [Uploadcare::Resources::Webhook]
      def self.create(target_url:, client: nil, config: Uploadcare.configuration, request_options: {}, **options)
        resolved_client = resolve_client(client: client, config: config)
        event = options.fetch(:event, 'file.uploaded')
        is_active = options.key?(:is_active) ? options[:is_active] : true
        payload = { target_url: target_url, event: event, is_active: is_active }
        payload[:signing_secret] = options[:signing_secret] if options[:signing_secret]
        payload[:version] = options[:version] if options[:version]

        response = Uploadcare::Result.unwrap(
          resolved_client.api.rest.webhooks.create(options: payload, request_options: request_options)
        )
        new(response, resolved_client)
      end

      # Update a webhook.
      #
      # @param id [Integer] Webhook ID
      # @param options [Hash] Webhook options to update
      # @param client [Uploadcare::Client, nil] Client instance
      # @param config [Uploadcare::Configuration] Configuration fallback
      # @param request_options [Hash] Request options
      # @return [Uploadcare::Resources::Webhook]
      def self.update(id:, client: nil, config: Uploadcare.configuration, request_options: {}, **options)
        resolved_client = resolve_client(client: client, config: config)
        payload = options.slice(:target_url, :event, :signing_secret, :version)
        payload[:is_active] = options[:is_active] if options.key?(:is_active)

        response = Uploadcare::Result.unwrap(
          resolved_client.api.rest.webhooks.update(id: id, options: payload, request_options: request_options)
        )
        new(response, resolved_client)
      end

      # Delete a webhook by target URL.
      #
      # @param target_url [String] Target URL of the webhook to delete
      # @param client [Uploadcare::Client, nil] Client instance
      # @param config [Uploadcare::Configuration] Configuration fallback
      # @param request_options [Hash] Request options
      # @return [nil]
      def self.delete(target_url:, client: nil, config: Uploadcare.configuration, request_options: {})
        resolved_client = resolve_client(client: client, config: config)
        Uploadcare::Result.unwrap(
          resolved_client.api.rest.webhooks.delete(target_url: target_url, request_options: request_options)
        )
      end

      class << self
        alias unsubscribe delete
      end
    end
  end
end

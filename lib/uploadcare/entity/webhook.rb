# frozen_string_literal: true

module Uploadcare
  module Entity
    # This serializer is responsible for webhook handling
    #
    # @see https://uploadcare.com/docs/api_reference/rest/webhooks/
    class Webhook < Entity
      client_service WebhookClient

      attr_entity :id, :created, :updated, :event, :target_url, :project, :is_active
    end
  end
end

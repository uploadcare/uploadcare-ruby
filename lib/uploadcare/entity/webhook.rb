# https://uploadcare.com/docs/api_reference/rest/webhooks/

module Uploadcare
  class Webhook < ApiStruct::Entity
    client_service WebhookClient

    attr_entity :id, :created, :updated, :event, :target_url, :project, :is_active
  end
end

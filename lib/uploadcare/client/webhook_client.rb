# https://uploadcare.com/api-refs/rest-api/v0.5.0/#tag/Webhook

module Uploadcare
  class WebhookClient < ApiStruct::Client
    rest_api

    def list
      headers = AuthenticationHeader.call(method: 'GET', uri: '/webhooks/')
      get(path: 'webhooks/', headers: headers)
    end
  end
end

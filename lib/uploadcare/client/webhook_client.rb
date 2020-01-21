# https://uploadcare.com/api-refs/rest-api/v0.5.0/#tag/Webhook

module Uploadcare
  class WebhookClient < ApiStruct::Client
    rest_api

    def list
      headers = AuthenticationHeader.call(method: 'GET', uri: '/webhooks/')
      get(path: 'webhooks/', headers: headers)
    end

    def delete(name)
      body = { 'name': name }.to_json
      headers = AuthenticationHeader.call(method: 'POST', uri: '/webhooks/unsubscribe/', content: body)
      post(path: 'webhooks/unsubscribe/', headers: headers, body: body)
    end
  end
end

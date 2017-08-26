require 'faraday'
require "faraday_middleware"

module Uploadcare
  module Connections
    class ApiConnection < Faraday::Connection

      def initialize options
        super options[:api_url_base] do |frd|
          auth_strategy = Auth.strategy(options)

          frd.headers['Accept'] = "application/vnd.uploadcare-v#{options[:api_version]}+json"
          frd.headers['User-Agent'] = Uploadcare::user_agent(options)

          # order of middleware matters!

          # :json middleware changes request body and thus should be before
          # uploadcare_auth which uses it to sign requests when secure auth
          # strategy is being used
          frd.request :json
          frd.request :uploadcare_auth, auth_strategy

          frd.response :uploadcare_raise_error
          frd.response :follow_redirects, limit: 3, callback: lambda{|old, env| auth_strategy.apply(env) }
          frd.response :uploadcare_parse_json

          frd.adapter :net_http # actually, default adapter, just to be clear
        end
      end

      # NOTE: Faraday doesn't support body in DELETE requests, but
      # Uploadcare API v0.5 requires clients to send array of UUIDs with
      # `DELETE /files/storage/` requests.
      #
      # This is on override of the original Faraday::Connection#delete method.
      #
      # As for now, there are no DELETE requests in Uploadcare REST API
      # which require params to be sent as URI params, so for simplicity
      # this method send all params in a body.
      def delete(url = nil, params = nil, headers = nil)
        run_request(:delete, url, nil, headers) { |request|
          # Original line from Faraday::Connection#delete method
          # request.params.update(params) if params

          # Monkey patch
          request.body = params if params

          yield(request) if block_given?
        }
      end

    end
  end
end

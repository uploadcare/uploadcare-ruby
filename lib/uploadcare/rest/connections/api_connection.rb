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

          # url_encoded changes request body and thus should be before
          # uploadcare_auth which uses it to sign requests when secure auth
          # strategy is being used
          frd.request :url_encoded
          frd.request :uploadcare_auth, auth_strategy

          frd.response :uploadcare_raise_error
          frd.response :follow_redirects, limit: 3, callback: lambda{|old, env| auth_strategy.apply(env) }
          frd.response :uploadcare_parse_json

          frd.adapter :net_http # actually, default adapter, just to be clear
        end
      end

    end
  end
end

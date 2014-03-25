require 'faraday'
require "faraday_middleware"
module Uploadcare
  module Connections
    class ApiConnection < Faraday::Connection
      def initialize options
        super options[:api_url_base] do |frd|
          frd.request :url_encoded
          frd.use ::FaradayMiddleware::FollowRedirects, limit: 3
          frd.adapter :net_http # actually, default adapter, just to be clear
          frd.headers['Authorization'] = "Uploadcare.Simple #{options[:public_key]}:#{options[:private_key]}"
          frd.headers['Accept'] = "application/vnd.uploadcare-v#{options[:api_version]}+json"
          frd.headers['User-Agent'] = Uploadcare::user_agent

          frd.response :raise_error
          frd.response :parse_json
        end
      end
    end
  end
end
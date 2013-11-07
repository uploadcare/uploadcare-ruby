require 'faraday'
require 'faraday_middleware'

module Uploadcare
  class Connections
    def self.api_connection options
      connection = Faraday.new url: options[:api_url_base] do |frd|
        frd.request :url_encoded
        frd.use FaradayMiddleware::FollowRedirects, limit: 3
        frd.adapter :net_http # actually, default adapter, just to be clear
        frd.headers['Authorization'] = "Uploadcare.Simple #{options[:public_key]}:#{options[:private_key]}"
        frd.headers['Accept'] = "application/vnd.uploadcare-v#{options[:api_version]}+json"
        frd.headers['User-Agent'] = Uploadcare::user_agent
      end

      connection
    end

    def self.upload_connection
      ca_path = '/etc/ssl/certs' if File.exists?('/etc/ssl/certs')

      connection = Faraday.new ssl: { ca_path: ca_path }, url: options[:upload_url_base] do |frd|
        frd.request :multipart
        frd.request :url_encoded
        frd.adapter Faraday.default_adapter
        frd.headers['User-Agent'] = Uploadcare::user_agent
      end

      connection
    end
  end
end
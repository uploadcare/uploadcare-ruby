# frozen_string_literal: true

require 'uri'
require 'addressable/uri'

module Uploadcare
  class RestClient
    include Uploadcare::ErrorHandler
    include Uploadcare::ThrottleHandler

    HTTP_GET = 'GET'

    attr_reader :config, :connection, :authenticator

    def initialize(config = Uploadcare.configuration)
      @config = config
      @connection = Faraday.new(url: config.rest_api_root) do |conn|
        conn.request :json
        conn.response :json, content_type: /\bjson$/
        conn.response :raise_error # Raises Faraday::Error on 4xx/5xx responses
      end
      @authenticator = Authenticator.new(config)
    end

    def make_request(method, path, params = {}, headers = {})
      handle_throttling do
        response = connection.public_send(method, path) do |req|
          prepare_request(req, method, path, params, headers)
        end
        response.body
      end
    rescue Faraday::Error => e
      handle_error(e)
    end

    def post(path, params = {}, headers = {})
      make_request(:post, path, params, headers)
    end

    def get(path, params = {}, headers = {})
      make_request(:get, path, params, headers)
    end

    def put(path, params = {}, headers = {})
      make_request(:put, path, params, headers)
    end

    def delete(path, params = {}, headers = {})
      make_request(:delete, path, params, headers)
    end

    private

    def prepare_request(req, method, path, params, headers)
      upcase_method_name = method.to_s.upcase
      uri = build_request_uri(path, params, upcase_method_name)

      prepare_headers(req, upcase_method_name, uri, params, headers)
      prepare_body_or_params(req, upcase_method_name, params)
    end

    def build_request_uri(path, params, method)
      # For GET requests, append query parameters to URI
      # For other methods (POST, PUT, DELETE), params go in body, not query string
      if method == HTTP_GET && !params.nil? && params.is_a?(Hash) && !params.empty?
        build_uri(path, params)
      else
        path
      end
    end

    def prepare_headers(req, method, uri, params, headers)
      # For authentication, we need to know the body content for signature generation
      body_content = if method == HTTP_GET
                       ''
                     else
                       params.nil? || params.empty? ? '' : params.to_json
                     end

      auth_headers = authenticator.headers(method, uri, body_content)
      req.headers.merge!(auth_headers)
      req.headers.merge!(headers)
    end

    def prepare_body_or_params(req, method, params)
      if method == HTTP_GET
        req.params.update(params) unless params.nil? || params.empty?
      else
        req.body = params.to_json unless params.nil? || params.empty?
      end
    end

    def build_uri(path, query_params = {})
      if query_params.empty?
        path
      else
        uri = Addressable::URI.parse(path)
        uri.query_values = query_params
        uri.to_s
      end
    end
  end
end

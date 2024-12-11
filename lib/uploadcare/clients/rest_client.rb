# frozen_string_literal: true

require 'uri'

module Uploadcare
  class RestClient
    include Uploadcare::ErrorHandler
    include Uploadcare::ThrottleHandler
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

    def del(path, params = {}, headers = {})
      make_request(:delete, path, params, headers)
    end

    private

    def prepare_request(req, method, path, params, headers)
      upcase_method_name = method.to_s.upcase
      uri = params.is_a?(Hash) ? build_uri(path, params) : path
      req.headers.merge!(authenticator.headers(upcase_method_name, uri))
      req.headers.merge!(headers)

      if upcase_method_name == 'GET'
        req.params.update(params) unless params.empty?
      else
        req.body = params.to_json unless params.empty?
      end
    end

    def build_uri(path, query_params = {})
      if query_params.empty?
        path
      else
        "#{path}?#{URI.encode_www_form(query_params)}"
      end
    end
  end
end

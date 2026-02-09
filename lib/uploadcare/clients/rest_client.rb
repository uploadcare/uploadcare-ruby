# frozen_string_literal: true

require 'uri'
require 'addressable/uri'

# HTTP client for Uploadcare REST API
#
# Provides low-level HTTP methods for making authenticated requests to the REST API.
# Handles authentication, throttling, and error handling automatically.
#
# This class is typically not used directly. Instead, use the specialized client
# classes (FileClient, GroupClient, etc.) which inherit from RestClient.
#
# @example Direct usage (not recommended)
#   client = Uploadcare::RestClient.new
#   response = client.get(path: '/files/')
#
# @see Uploadcare::FileClient
# @see Uploadcare::GroupClient
# @see https://uploadcare.com/api-refs/rest-api/
class Uploadcare::RestClient
  include Uploadcare::ErrorHandler
  include Uploadcare::ThrottleHandler

  # HTTP method name for GET requests.
  #
  # @api private
  HTTP_GET = 'GET'

  # @return [Uploadcare::Configuration] Configuration object
  attr_reader :config

  # @return [Faraday::Connection] HTTP connection instance
  attr_reader :connection

  # @return [Uploadcare::Authenticator] Authenticator for signing requests
  attr_reader :authenticator

  # Initialize a new REST API client
  #
  # @param config [Uploadcare::Configuration] Configuration object (defaults to global config)
  # @return [Uploadcare::RestClient] new client instance
  def initialize(config: Uploadcare.configuration)
    @config = config
    @connection = Faraday.new(url: config.rest_api_root) do |conn|
      conn.request :json
      conn.response :json, content_type: /\bjson$/
      conn.response :raise_error # Raises Faraday::Error on 4xx/5xx responses
    end
    @authenticator = Uploadcare::Authenticator.new(config: config)
  end

  # Make an HTTP request to the REST API
  #
  # @param method [Symbol] HTTP method (:get, :post, :put, :delete)
  # @param path [String] API endpoint path
  # @param params [Hash] Request parameters (query params for GET, body for others)
  # @param headers [Hash] Additional request headers
  # @return [Hash] Parsed JSON response body
  # @raise [Uploadcare::Exception::RequestError] on API errors
  def make_request(method:, path:, params: {}, headers: {}, request_options: {})
    handle_throttling(max_attempts: request_options[:max_throttle_attempts]) do
      response = connection.public_send(method, path) do |req|
        prepare_request(req, method, path, params, headers, request_options)
      end
      response.body
    end
  rescue Faraday::Error => e
    handle_error(e)
  end

  # Make a POST request
  #
  # @param path [String] API endpoint path
  # @param params [Hash] Request body parameters
  # @param headers [Hash] Additional request headers
  # @return [Hash] Parsed JSON response body
  def post(path:, params: {}, headers: {}, request_options: {})
    request(method: :post, path: path, params: params, headers: headers, request_options: request_options)
  end

  # Make a GET request
  #
  # @param path [String] API endpoint path
  # @param params [Hash] Query parameters
  # @param headers [Hash] Additional request headers
  # @return [Hash] Parsed JSON response body
  def get(path:, params: {}, headers: {}, request_options: {})
    request(method: :get, path: path, params: params, headers: headers, request_options: request_options)
  end

  # Make a PUT request
  #
  # @param path [String] API endpoint path
  # @param params [Hash] Request body parameters
  # @param headers [Hash] Additional request headers
  # @return [Hash] Parsed JSON response body
  def put(path:, params: {}, headers: {}, request_options: {})
    request(method: :put, path: path, params: params, headers: headers, request_options: request_options)
  end

  # Make a DELETE request
  #
  # @param path [String] API endpoint path
  # @param params [Hash] Request body parameters
  # @param headers [Hash] Additional request headers
  # @return [Hash] Parsed JSON response body
  def delete(path:, params: {}, headers: {}, request_options: {})
    request(method: :delete, path: path, params: params, headers: headers, request_options: request_options)
  end

  # Wraps a request in a Result object.
  #
  # @param method [Symbol] HTTP method
  # @param path [String] API path
  # @param params [Hash] request parameters
  # @param headers [Hash] request headers
  # @return [Uploadcare::Result]
  def request(method:, path:, params: {}, headers: {}, request_options: {})
    Uploadcare::Result.capture do
      make_request(method: method, path: path, params: params, headers: headers, request_options: request_options)
    end
  end

  private

  def prepare_request(req, method, path, params, headers, request_options)
    upcase_method_name = method.to_s.upcase
    uri = build_request_uri(path, params, upcase_method_name)

    prepare_headers(req, upcase_method_name, uri, params, headers)
    prepare_body_or_params(req, upcase_method_name, params)
    apply_request_options(req, request_options)
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

    content_type = headers['Content-Type'] || authenticator.default_headers['Content-Type']
    auth_headers = authenticator.headers(method, uri, body_content, content_type)
    req.headers.merge!(auth_headers)
    req.headers.merge!(headers)
  end

  def prepare_body_or_params(req, method, params)
    if method == HTTP_GET
      req.params.update(params) unless params.nil? || params.empty?
    else
      return if params.nil? || params.empty?

      req.body = params.is_a?(String) ? params.to_json : params
    end
  end

  def apply_request_options(req, request_options)
    return if request_options.nil? || request_options.empty?

    req.options.timeout = request_options[:timeout] if request_options[:timeout]
    req.options.open_timeout = request_options[:open_timeout] if request_options[:open_timeout]
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

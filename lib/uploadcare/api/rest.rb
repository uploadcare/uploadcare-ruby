# frozen_string_literal: true

require 'faraday'
require 'uri'

# Base client for the Uploadcare REST API.
#
# Provides authenticated HTTP methods (GET, POST, PUT, DELETE) for all REST API
# endpoints. Includes automatic error handling and throttle retry logic.
#
# Endpoint classes are accessed via lazy-loaded accessors:
#   rest = Uploadcare::Api::Rest.new(config: config)
#   rest.files.list
#   rest.groups.info(uuid: "...")
#
# @see https://uploadcare.com/api-refs/rest-api/v0.7.0/
class Uploadcare::Api::Rest
  include Uploadcare::Internal::ErrorHandler
  include Uploadcare::Internal::ThrottleHandler

  # Verb name used when deciding whether params belong in the query string.
  HTTP_GET = 'GET'

  # @return [Uploadcare::Configuration]
  attr_reader :config

  # @return [Faraday::Connection]
  attr_reader :connection

  # @return [Uploadcare::Internal::Authenticator]
  attr_reader :authenticator

  # Initialize a new REST API client.
  #
  # @param config [Uploadcare::Configuration] Configuration object (defaults to global config)
  def initialize(config: Uploadcare.configuration)
    @config = config
    @memo_mutex = Mutex.new
    @connection = Faraday.new(url: config.rest_api_root) do |conn|
      conn.request :json
      conn.response :json, content_type: /\bjson$/
      conn.response :raise_error
    end
    @authenticator = Uploadcare::Internal::Authenticator.new(config: config)
  end

  # --- Endpoint accessors ---

  # @return [Uploadcare::Api::Rest::Files] File operations endpoint
  def files
    memoized(:@files) { Uploadcare::Api::Rest::Files.new(rest: self) }
  end

  # @return [Uploadcare::Api::Rest::Groups] Group operations endpoint
  def groups
    memoized(:@groups) { Uploadcare::Api::Rest::Groups.new(rest: self) }
  end

  # @return [Uploadcare::Api::Rest::Project] Project information endpoint
  def project
    memoized(:@project) { Uploadcare::Api::Rest::Project.new(rest: self) }
  end

  # @return [Uploadcare::Api::Rest::Webhooks] Webhook operations endpoint
  def webhooks
    memoized(:@webhooks) { Uploadcare::Api::Rest::Webhooks.new(rest: self) }
  end

  # @return [Uploadcare::Api::Rest::FileMetadata] File metadata operations endpoint
  def file_metadata
    memoized(:@file_metadata) { Uploadcare::Api::Rest::FileMetadata.new(rest: self) }
  end

  # @return [Uploadcare::Api::Rest::Addons] Add-on operations endpoint
  def addons
    memoized(:@addons) { Uploadcare::Api::Rest::Addons.new(rest: self) }
  end

  # @return [Uploadcare::Api::Rest::DocumentConversions] Document conversion endpoint
  def document_conversions
    memoized(:@document_conversions) { Uploadcare::Api::Rest::DocumentConversions.new(rest: self) }
  end

  # @return [Uploadcare::Api::Rest::VideoConversions] Video conversion endpoint
  def video_conversions
    memoized(:@video_conversions) { Uploadcare::Api::Rest::VideoConversions.new(rest: self) }
  end

  # --- HTTP methods ---

  # Make an HTTP request to the REST API.
  #
  # @param method [Symbol] HTTP method (:get, :post, :put, :delete)
  # @param path [String] API endpoint path
  # @param params [Hash, Array, String] Request parameters
  # @param headers [Hash] Additional request headers
  # @param request_options [Hash] Request options (timeout, etc.)
  # @return [Hash, Array, nil] Parsed JSON response body
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

  # Make a POST request wrapped in a Result.
  #
  # @param path [String] API endpoint path
  # @param params [Hash] Request body parameters
  # @param headers [Hash] Additional request headers
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result]
  def post(path:, params: {}, headers: {}, request_options: {})
    request(method: :post, path: path, params: params, headers: headers, request_options: request_options)
  end

  # Make a GET request wrapped in a Result.
  #
  # @param path [String] API endpoint path
  # @param params [Hash] Query parameters
  # @param headers [Hash] Additional request headers
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result]
  def get(path:, params: {}, headers: {}, request_options: {})
    request(method: :get, path: path, params: params, headers: headers, request_options: request_options)
  end

  # Make a PUT request wrapped in a Result.
  #
  # @param path [String] API endpoint path
  # @param params [Hash] Request body parameters
  # @param headers [Hash] Additional request headers
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result]
  def put(path:, params: {}, headers: {}, request_options: {})
    request(method: :put, path: path, params: params, headers: headers, request_options: request_options)
  end

  # Make a DELETE request wrapped in a Result.
  #
  # @param path [String] API endpoint path
  # @param params [Hash] Request body parameters
  # @param headers [Hash] Additional request headers
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result]
  def delete(path:, params: {}, headers: {}, request_options: {})
    request(method: :delete, path: path, params: params, headers: headers, request_options: request_options)
  end

  # Wraps a request in a Result object.
  #
  # @param method [Symbol] HTTP method
  # @param path [String] API path
  # @param params [Hash] Request parameters
  # @param headers [Hash] Request headers
  # @param request_options [Hash] Request options
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
    if method == HTTP_GET && !params.nil? && params.is_a?(Hash) && !params.empty?
      build_uri(path, params)
    else
      path
    end
  end

  def prepare_headers(req, method, uri, params, headers)
    body_content = body_content_for_signature(method, params)
    content_type = extract_content_type(headers) || authenticator.default_headers['Content-Type']
    auth_headers = authenticator.headers(method, uri, body_content, content_type)
    normalized_headers = normalize_content_type_header(headers, content_type)
    req.headers.merge!(auth_headers)
    req.headers.merge!(normalized_headers)
  end

  def body_content_for_signature(method, params)
    return '' if method == HTTP_GET
    return '' if params.nil? || (params.respond_to?(:empty?) && params.empty?)
    return params if params.is_a?(String)

    params.to_json
  end

  def prepare_body_or_params(req, method, params)
    if method == HTTP_GET
      req.params.update(params) unless params.nil? || params.empty?
    else
      return if params.nil? || params.empty?

      req.body = params
    end
  end

  def apply_request_options(req, request_options)
    return if request_options.nil? || request_options.empty?

    req.options.timeout = request_options[:timeout] if request_options[:timeout]
    req.options.open_timeout = request_options[:open_timeout] if request_options[:open_timeout]
  end

  def extract_content_type(headers)
    headers['Content-Type'] || headers['content-type'] || headers[:content_type] || headers[:'Content-Type']
  end

  def normalize_content_type_header(headers, content_type)
    normalized_headers = headers.dup
    normalized_headers.delete('content-type')
    normalized_headers.delete(:content_type)
    normalized_headers.delete(:'Content-Type')
    normalized_headers['Content-Type'] = content_type if content_type
    normalized_headers
  end

  def build_uri(path, query_params = {})
    if query_params.empty?
      path
    else
      separator = path.include?('?') ? '&' : '?'
      params_encoder = connection.options.params_encoder || Faraday::Utils.default_params_encoder
      encoded_query = params_encoder.encode(query_params)
      "#{path}#{separator}#{encoded_query}"
    end
  end

  def memoized(ivar)
    cached = instance_variable_get(ivar)
    return cached if cached

    @memo_mutex.synchronize do
      instance_variable_get(ivar) || instance_variable_set(ivar, yield)
    end
  end
end

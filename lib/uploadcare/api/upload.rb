# frozen_string_literal: true

require 'faraday'
require 'faraday/multipart'
require 'mime/types'
require 'securerandom'
require 'uri'
require 'addressable/uri'

# Base client for the Uploadcare Upload API.
#
# Provides HTTP methods for upload endpoints using multipart/form-data encoding.
# Authentication is handled via public key in request parameters (no HMAC signing).
#
# Endpoint classes are accessed via lazy-loaded accessors:
#   upload = Uploadcare::Api::Upload.new(config: config)
#   upload.files.direct(file: file_obj)
#   upload.groups.create(files: ["uuid1", "uuid2"])
#
# @see https://uploadcare.com/api-refs/upload-api/
class Uploadcare::Api::Upload
  include Uploadcare::Internal::ErrorHandler
  include Uploadcare::Internal::ThrottleHandler

  # @return [Uploadcare::Configuration]
  attr_reader :config

  # @return [Faraday::Connection]
  attr_reader :connection

  # Initialize a new Upload API client.
  #
  # @param config [Uploadcare::Configuration] Configuration object
  def initialize(config: Uploadcare.configuration)
    @config = config
    @connection = Faraday.new(url: config.upload_api_root) do |conn|
      conn.request :multipart
      conn.request :url_encoded
      conn.response :json, content_type: /\bjson$/
      conn.response :raise_error
      conn.response :logger if ENV['DEBUG']
      conn.adapter Faraday.default_adapter
    end
  end

  # --- Endpoint accessors ---

  # @return [Uploadcare::Api::Upload::Files] File upload operations
  def files
    @files ||= Uploadcare::Api::Upload::Files.new(upload: self)
  end

  # @return [Uploadcare::Api::Upload::Groups] Group operations via Upload API
  def groups
    @groups ||= Uploadcare::Api::Upload::Groups.new(upload: self)
  end

  # --- HTTP methods ---

  # Make a GET request to the Upload API wrapped in a Result.
  #
  # @param path [String] API endpoint path
  # @param params [Hash] Query parameters
  # @param headers [Hash] Additional request headers
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result]
  def get(path:, params: {}, headers: {}, request_options: {})
    Uploadcare::Result.capture do
      make_request(:get, path, params, headers, request_options)
    end
  end

  # Make a POST request to the Upload API wrapped in a Result.
  #
  # @param path [String] API endpoint path
  # @param params [Hash] Request body parameters
  # @param headers [Hash] Additional request headers
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result]
  def post(path:, params: {}, headers: {}, request_options: {})
    Uploadcare::Result.capture do
      make_request(:post, path, params, headers, request_options)
    end
  end

  # Upload binary data to a presigned URL (for multipart uploads).
  #
  # @param presigned_url [String] Presigned URL from multipart_start
  # @param part_data [String, IO] Binary data for this part
  # @param max_retries [Integer] Maximum retry attempts (default: 3)
  # @return [Boolean] true on success
  # @raise [Uploadcare::Exception::MultipartUploadError] on failure after retries
  def upload_part_to_url(presigned_url, part_data, max_retries: 3)
    retries = 0
    begin
      uri = URI.parse(presigned_url)
      conn = Faraday.new(url: "#{uri.scheme}://#{uri.host}") do |f|
        f.adapter Faraday.default_adapter
      end

      data = part_data.respond_to?(:read) ? part_data.read : part_data

      response = conn.put(uri.request_uri) do |req|
        req.headers['Content-Type'] = 'application/octet-stream'
        req.body = data
      end

      unless response.status >= 200 && response.status < 300
        raise Uploadcare::Exception::MultipartUploadError,
              "Failed to upload part: HTTP #{response.status}"
      end

      true
    rescue StandardError => e
      retries += 1
      if retries >= max_retries
        raise Uploadcare::Exception::MultipartUploadError,
              "Failed to upload part after #{max_retries} retries: #{e.message}"
      end

      sleep(2**retries)
      retry
    end
  end

  protected

  def make_request(method, path, params = {}, headers = {}, request_options = {})
    handle_throttling(max_attempts: request_options[:max_throttle_attempts]) do
      response = connection.public_send(method, path) do |req|
        prepare_request(req, method, path, params, headers, request_options)
      end
      handle_response(response)
    end
  rescue Faraday::Error => e
    handle_error(e)
  end

  def handle_response(response)
    return handle_error_response(response) unless success_response?(response)

    parse_success_response(response)
  rescue JSON::ParserError => e
    handle_json_error(e, response)
  rescue Faraday::Error => e
    handle_faraday_error(e)
  end

  private

  def prepare_request(req, method, path, params, headers, request_options)
    upcase_method_name = method.to_s.upcase
    uri = path
    uri = build_request_uri(path, params, upcase_method_name) if upcase_method_name == 'GET'

    prepare_headers(req, upcase_method_name, uri, headers)
    prepare_body_or_params(req, upcase_method_name, params)
    apply_request_options(req, request_options)
  end

  def build_request_uri(path, params, method)
    return path unless method == 'GET' && params.is_a?(Hash) && !params.empty?

    uri = Addressable::URI.parse(path)
    uri.query_values = params
    uri.to_s
  end

  def prepare_headers(req, _method, _uri, headers)
    req.headers['User-Agent'] ||= Uploadcare::Internal::UserAgent.call(config: config)
    req.headers.merge!(headers)
  end

  def prepare_body_or_params(req, method, params)
    if method == 'GET'
      req.params.update(params) unless params.empty?
    else
      req.body = params unless params.empty?
    end
  end

  def apply_request_options(req, request_options)
    return if request_options.nil? || request_options.empty?

    req.options.timeout = request_options[:timeout] if request_options[:timeout]
    req.options.open_timeout = request_options[:open_timeout] if request_options[:open_timeout]
  end

  def success_response?(response)
    response.status >= 200 && response.status < 300
  end

  def handle_error_response(response)
    raise Uploadcare::Exception::UploadError, "Upload API error: #{response.status} #{response.body}"
  end

  def parse_success_response(response)
    return {} if response.body.nil? || (response.body.is_a?(String) && response.body.strip.empty?)
    return response.body if response.body.is_a?(Hash)

    JSON.parse(response.body)
  end

  def handle_json_error(error, response)
    config.logger&.error("Invalid JSON response: #{error.message}")
    success_response?(response) ? {} : response.body
  end

  def handle_faraday_error(error)
    if error.response
      raise Uploadcare::Exception::RequestError,
            "HTTP #{error.response[:status]}: #{error.response[:body]}"
    end

    raise Uploadcare::Exception::RequestError, "Network error: #{error.message}"
  end
end

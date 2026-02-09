# frozen_string_literal: true

require 'digest/md5'
require 'addressable/uri'
require 'openssl'
require 'time'

# Handles authentication for Uploadcare REST API requests
#
# Supports two authentication modes:
# - Simple authentication: Basic auth with public_key:secret_key
# - Secure authentication: HMAC-SHA1 signature-based authentication
#
# @example Using the authenticator
#   authenticator = Uploadcare::Authenticator.new(config: config)
#   headers = authenticator.headers('GET', '/files/', '')
#
# @see https://uploadcare.com/docs/api_reference/rest/requests_auth/
class Uploadcare::Authenticator
  # @return [Hash] Default headers included in all requests
  attr_reader :default_headers

  # Initialize a new Authenticator
  #
  # @param config [Uploadcare::Configuration] Configuration object with API credentials
  # @return [Uploadcare::Authenticator] new authenticator instance
  def initialize(config:)
    @config = config
    @default_headers = {
      'Accept' => 'application/vnd.uploadcare-v0.7+json',
      'Content-Type' => 'application/json',
      'User-Agent' => Uploadcare::Param::UserAgent.call(config: config)
    }
  end

  # Generate authentication headers for an API request
  #
  # @param http_method [String] HTTP method (GET, POST, PUT, DELETE)
  # @param uri [String] Request URI path
  # @param body [String] Request body content (default: '')
  # @param content_type [String] Content-Type header value (default: 'application/json')
  # @return [Hash] Headers hash including authentication
  # @raise [Uploadcare::Exception::AuthError] if public key is blank when using secure auth
  def headers(http_method, uri, body = '', content_type = 'application/json')
    return simple_auth_headers(content_type) if @config.auth_type == 'Uploadcare.Simple'
    if @config.secret_key.nil? || @config.secret_key.empty?
      return @default_headers.merge({ 'Content-Type' => content_type })
    end

    validate_public_key
    secure_auth_headers(http_method, uri, body, content_type)
  end

  private

  def simple_auth_headers(content_type)
    @default_headers.merge({ 'Content-Type' => content_type,
                             'Authorization' => "#{@config.auth_type} #{@config.public_key}:#{@config.secret_key}" })
  end

  def validate_public_key
    return unless @config.public_key.nil? || @config.public_key.empty?

    raise Uploadcare::Exception::AuthError, 'Public Key is blank.'
  end

  def secure_auth_headers(http_method, uri, body, content_type)
    date = Time.now.gmtime.strftime('%a, %d %b %Y %H:%M:%S GMT')
    signature = generate_signature(http_method, uri, body, content_type, date)
    auth_headers = { 'Authorization' => "Uploadcare #{@config.public_key}:#{signature}", 'Date' => date }
    @default_headers.merge({ 'Content-Type' => content_type }).merge(auth_headers)
  end

  def generate_signature(http_method, uri, body, content_type, date)
    # Ensure URI starts with / for signature
    normalized_uri = uri.start_with?('/') ? uri : "/#{uri}"

    sign_string = [
      http_method.upcase,
      Digest::MD5.hexdigest(body),
      content_type,
      date,
      normalized_uri
    ].join("\n")

    OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('sha1'),
      @config.secret_key,
      sign_string
    )
  end
end

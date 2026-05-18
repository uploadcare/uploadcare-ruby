# frozen_string_literal: true

require 'openssl'
require 'time'

# Handles authentication for Uploadcare REST API requests.
#
# Supports two authentication modes:
# - Simple authentication: Basic auth with public_key:secret_key
# - Secure authentication: signature-based authentication
#
# @example Using the authenticator
#   authenticator = Uploadcare::Internal::Authenticator.new(config: config)
#   headers = authenticator.headers('GET', '/files/', '')
#
# @see https://uploadcare.com/docs/api_reference/rest/requests_auth/
class Uploadcare::Internal::Authenticator
  BODY_DIGEST_NAME = 'MD5'
  SIGNATURE_DIGEST_NAME = 'SHA1'

  # @return [Hash] Default headers included in all requests
  attr_reader :default_headers

  # Initialize a new Authenticator.
  #
  # @param config [Uploadcare::Configuration] Configuration object with API credentials
  def initialize(config:)
    @config = config
    @default_headers = {
      'Accept' => 'application/vnd.uploadcare-v0.7+json',
      'User-Agent' => Uploadcare::Internal::UserAgent.call(config: config)
    }
  end

  # Generate authentication headers for an API request.
  #
  # @param http_method [String] HTTP method (GET, POST, PUT, DELETE)
  # @param uri [String] Request URI path
  # @param body [String] Request body content (default: '')
  # @param content_type [String] Content-Type header value (default: 'application/json')
  # @return [Hash] Headers hash including authentication
  # @raise [Uploadcare::Exception::AuthError] if credentials are blank when using secure auth
  def headers(http_method, uri, body = '', content_type = nil)
    resolved_content_type = content_type || 'application/json'
    raise Uploadcare::Exception::AuthError, 'Secret Key is blank.' if @config.secret_key.to_s.empty?

    validate_public_key

    return simple_auth_headers(resolved_content_type) if @config.auth_type == 'Uploadcare.Simple'

    secure_auth_headers(http_method, uri, body, resolved_content_type)
  end

  private

  def simple_auth_headers(content_type)
    @default_headers.merge(
      'Content-Type' => content_type,
      'Authorization' => "#{@config.auth_type} #{@config.public_key}:#{@config.secret_key}"
    )
  end

  def validate_public_key
    return unless @config.public_key.nil? || @config.public_key.empty?

    raise Uploadcare::Exception::AuthError, 'Public Key is blank.'
  end

  def secure_auth_headers(http_method, uri, body, content_type)
    date = Time.now.gmtime.strftime('%a, %d %b %Y %H:%M:%S GMT')
    signature = generate_signature(http_method, uri, body, content_type, date)
    auth_headers = { 'Authorization' => "Uploadcare #{@config.public_key}:#{signature}", 'Date' => date }
    @default_headers.merge('Content-Type' => content_type).merge(auth_headers)
  end

  def generate_signature(http_method, uri, body, content_type, date)
    normalized_uri = uri.start_with?('/') ? uri : "/#{uri}"

    sign_string = [
      http_method.upcase,
      body_digest(body),
      content_type,
      date,
      normalized_uri
    ].join("\n")

    OpenSSL::HMAC.hexdigest(
      signature_digest,
      @config.secret_key,
      sign_string
    )
  end

  def body_digest(body)
    OpenSSL::Digest.new(BODY_DIGEST_NAME).hexdigest(body)
  end

  def signature_digest
    OpenSSL::Digest.new(SIGNATURE_DIGEST_NAME)
  end
end

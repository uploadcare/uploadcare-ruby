# frozen_string_literal: true

require 'digest/md5'
require 'addressable/uri'
require 'openssl'
require 'time'

module Uploadcare
  class Authenticator
    attr_reader :default_headers

    def initialize(config)
      @config = config
      @default_headers = {
        'Accept' => 'application/vnd.uploadcare-v0.7+json',
        'Content-Type' => 'application/json'
      }
    end

    def headers(http_method, uri, body = '', content_type = 'application/json')
      return simple_auth_headers if @config.auth_type == 'Uploadcare.Simple'
      return @default_headers if @config.secret_key.nil? || @config.secret_key.empty?

      validate_public_key
      secure_auth_headers(http_method, uri, body, content_type)
    end

    private

    def simple_auth_headers
      @default_headers.merge({ 'Authorization' => "#{@config.auth_type} #{@config.public_key}:#{@config.secret_key}" })
    end

    def validate_public_key
      return unless @config.public_key.nil? || @config.public_key.empty?

      raise Uploadcare::Exception::AuthError, 'Public Key is blank.'
    end

    def secure_auth_headers(http_method, uri, body, content_type)
      date = Time.now.gmtime.strftime('%a, %d %b %Y %H:%M:%S GMT')
      signature = generate_signature(http_method, uri, body, content_type, date)
      auth_headers = { 'Authorization' => "Uploadcare #{@config.public_key}:#{signature}", 'Date' => date }
      @default_headers.merge(auth_headers)
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
end

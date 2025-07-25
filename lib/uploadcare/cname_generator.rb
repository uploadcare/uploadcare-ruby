# frozen_string_literal: true

# lib/uploadcare/client/cname_generator.rb
require 'digest'

module Uploadcare
  # CNAME generator for Uploadcare CDN
  # see https://uploadcare.com/docs/delivery/cdn
  class CnameGenerator
    CNAME_PREFIX_LEN = 10

    class << self
      def cdn_base_postfix
        @cdn_base_postfix ||= begin
          uri = URI.parse(Uploadcare.config.cdn_base_postfix)
          uri.host = "#{custom_cname}.#{uri.host}"
          uri.to_s
        rescue URI::InvalidURIError => e
          raise Uploadcare::Exception::ConfigurationError, "Invalid cdn_base_postfix URL: #{e.message}"
        end
      end

      def generate_cname
        custom_cname
      end

      private

      # Generate CNAME prefix
      def custom_cname
        @custom_cname ||= begin
          public_key = Uploadcare.config.public_key
          raise Uploadcare::Exception::ConfigurationError, "Invalid public_key: #{public_key}" if public_key.nil?

          sha256_hex = Digest::SHA256.hexdigest(public_key)
          sha256_hex = sha256_hex.to_i(16)
          sha256_base36 = sha256_hex.to_s(36)
          sha256_base36[0, CNAME_PREFIX_LEN]
        end
      end
    end
  end
end

# frozen_string_literal: true

# lib/uploadcare/client/cname_generator.rb
require 'digest'

# CNAME generator for Uploadcare CDN.
# @see https://uploadcare.com/docs/delivery/cdn
class Uploadcare::CnameGenerator
  # CNAME prefix length.
  CNAME_PREFIX_LEN = 10

  class << self
    # Build CDN base URL with a generated CNAME prefix.
    #
    # @return [String]
    def cdn_base_postfix
      @cdn_base_postfix_cache ||= {}
      key = [Uploadcare.configuration.cdn_base_postfix, Uploadcare.configuration.public_key]
      @cdn_base_postfix_cache[key] ||= begin
        uri = URI.parse(Uploadcare.configuration.cdn_base_postfix)
        uri.host = "#{generate_cname}.#{uri.host}"
        uri.to_s
      rescue URI::InvalidURIError => e
        raise Uploadcare::Exception::ConfigurationError, "Invalid cdn_base_postfix URL: #{e.message}"
      end
    end

    # Generate a CNAME prefix for the current public key.
    #
    # @return [String]
    def generate_cname
      custom_cname
    end

    private

    # Generate CNAME prefix
    def custom_cname
      @custom_cname_cache ||= {}
      public_key = Uploadcare.configuration.public_key
      raise Uploadcare::Exception::ConfigurationError, "Invalid public_key: #{public_key}" if public_key.nil?

      @custom_cname_cache[public_key] ||= begin
        sha256_hex = Digest::SHA256.hexdigest(public_key)
        sha256_hex = sha256_hex.to_i(16)
        sha256_base36 = sha256_hex.to_s(36)
        sha256_base36[0, CNAME_PREFIX_LEN]
      end
    end
  end
end

# frozen_string_literal: true

# lib/uploadcare/client/cname_generator.rb
require 'digest'
require 'uri'

# CNAME generator for Uploadcare CDN.
# @see https://uploadcare.com/docs/delivery/cdn
class Uploadcare::CnameGenerator
  # CNAME prefix length.
  CNAME_PREFIX_LEN = 10

  class << self
    # Build CDN base URL with a generated CNAME prefix.
    #
    # @param config [Uploadcare::Configuration]
    # @return [String]
    def cdn_base_postfix(config: Uploadcare.configuration)
      @cdn_base_postfix_cache ||= {}
      key = [config.cdn_base_postfix, config.public_key]
      @cdn_base_postfix_cache[key] ||= begin
        uri = URI.parse(config.cdn_base_postfix)
        uri.host = "#{generate_cname(public_key: config.public_key)}.#{uri.host}"
        uri.to_s
      rescue URI::InvalidURIError => e
        raise Uploadcare::Exception::ConfigurationError, "Invalid cdn_base_postfix URL: #{e.message}"
      end
    end

    # Generate a CNAME prefix for the current public key.
    #
    # @param public_key [String]
    # @return [String]
    def generate_cname(public_key: Uploadcare.configuration.public_key)
      custom_cname(public_key)
    end

    private

    # Generate CNAME prefix
    def custom_cname(public_key = Uploadcare.configuration.public_key)
      @custom_cname_cache ||= {}
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

# frozen_string_literal: true

# lib/uploadcare/client/cname_generator.rb
require 'digest'

module Uploadcare
  # CNAME generator for Uploadcare CDN
  # see https://uploadcare.com/docs/delivery/cdn
  class CnameGenerator
    CNAME_PREFIX_LEN = 10

    class << self
      def custom_cdn_base
        @custom_cdn_base ||= begin
          uri = URI.parse(Uploadcare.config.custom_cdn_base)
          uri.host = "#{generate_cname}.#{uri.host}"
          uri.to_s
        end
      end

      def generate_cname
        custom_cname
      end

      private

      # Generate CNAME prefix
      def custom_cname
        @custom_cname ||= begin
          sha256_hex = Digest::SHA256.hexdigest(Uploadcare.config.public_key)
          sha256_hex = sha256_hex.to_i(16)
          sha256_base36 = sha256_hex.to_s(36)
          sha256_base36[0, CNAME_PREFIX_LEN]
        end
      end
    end
  end
end

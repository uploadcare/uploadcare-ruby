# frozen_string_literal: true

require 'digest'
require 'uri'

module Uploadcare
  class CnameGenerator
    class << self
      def generate(public_key)
        return nil unless public_key

        hash = Digest::SHA256.hexdigest(public_key)
        hash.to_i(16).to_s(36)[0, 10]
      end

      def cdn_base_url(public_key, cdn_base_postfix)
        subdomain = generate(public_key)
        return cdn_base_postfix unless subdomain

        uri = URI.parse(cdn_base_postfix)
        uri.host = "#{subdomain}.#{uri.host}"
        uri.to_s
      end
    end
  end
end
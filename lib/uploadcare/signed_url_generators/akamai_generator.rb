# frozen_string_literal: true

require 'openssl'
require 'base64'

module Uploadcare
  module SignedUrlGenerators
    class AkamaiGenerator < BaseGenerator
      def generate_url(uuid, expiration = nil)
        expiration ||= Time.now.to_i + 300 # 5 minutes default
        acl = "/#{uuid}/"
        auth_token = generate_token(acl, expiration)

        build_url("/#{uuid}/", {
          token: "exp=#{expiration}~acl=#{acl}~hmac=#{auth_token}"
        })
      end

      private

      def generate_token(acl, expiration)
        string_to_sign = "exp=#{expiration}~acl=#{acl}"
        hmac = OpenSSL::HMAC.digest('sha256', hex_to_binary(secret_key), string_to_sign)
        Base64.strict_encode64(hmac).tr('+/', '-_').delete('=')
      end

      def hex_to_binary(hex_string)
        [hex_string].pack('H*')
      end
    end
  end
end
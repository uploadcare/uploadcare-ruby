# frozen_string_literal: true

require 'digest/md5'
require 'param/secure_auth_header'
require 'param/simple_auth_header'

module Uploadcare
  module Param
    # This object returns headers needed for authentication
    # This authentication method is more secure, but more tedious
    class AuthenticationHeader
      # @see https://uploadcare.com/docs/api_reference/rest/requests_auth/#auth-uploadcare
      def self.call(options = {})
        validate_keys
        case Uploadcare.config.auth_type
        when 'Uploadcare'
          SecureAuthHeader.call(options)
        when 'Uploadcare.Simple'
          SimpleAuthHeader.call
        else
          raise ArgumentError, "Unknown auth_scheme: '#{Uploadcare.config.auth_type}'"
        end
      end

      private

      def self.validate_keys
        raise AuthError, "Public Key is blank." if Uploadcare.config.public_key.empty?
        raise AuthError, "Secret Key is blank." if Uploadcare.config.secret_key.empty?
      end
    end
  end
end

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
        validate_auth_config
        case Uploadcare.config.auth_type
        when 'Uploadcare'
          SecureAuthHeader.call(options)
        when 'Uploadcare.Simple'
          SimpleAuthHeader.call
        else
          raise ArgumentError, "Unknown auth_scheme: '#{Uploadcare.config.auth_type}'"
        end
      end

      def self.validate_auth_config
        if empty_config_for?(Uploadcare.config.public_key)
          raise Uploadcare::Exception::AuthError,
                'Public Key is blank.'
        end
        return unless empty_config_for?(Uploadcare.config.secret_key)

        raise Uploadcare::Exception::AuthError,
              'Secret Key is blank.'
      end

      def self.empty_config_for?(value)
        value.nil? || value.empty?
      end
    end
  end
end

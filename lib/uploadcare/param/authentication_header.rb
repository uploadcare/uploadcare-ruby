# frozen_string_literal: true

require 'digest/md5'
require 'param/secure_auth_header'
require 'param/simple_auth_header'

module Uploadcare
  module Param
    # This object returns headers needed for authentication
    # This authentication method is more secure, but more tedious
    class AuthenticationHeader
      include Exception
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
        raise AuthError, 'Public Key is blank.' if is_blank?(Uploadcare.config.public_key)
        raise AuthError, 'Secret Key is blank.' if is_blank?(Uploadcare.config.secret_key)
      end

      # rubocop:disable Naming/PredicateName
      def self.is_blank?(value)
        value.nil? || value.empty?
      end
      # rubocop:enable Naming/PredicateName
    end
  end
end

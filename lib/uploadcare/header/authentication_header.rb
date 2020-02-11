# frozen_string_literal: true

# This object returns headers needed for authentication
# This authentication method is more secure, but more tedious
# https://uploadcare.com/docs/api_reference/rest/requests_auth/#auth-uploadcare

require 'digest/md5'

module Uploadcare
  class AuthenticationHeader
    def self.call(**options)
      case AUTH_TYPE
      when 'Uploadcare'
        SecureAuthHeader.call(options)
      when 'Uploadcare.Simple'
        SimpleAuthHeader.call
      else
        raise ArgumentError, "Unknown auth_scheme: '#{AUTH_TYPE}'"
      end
    end
  end
end

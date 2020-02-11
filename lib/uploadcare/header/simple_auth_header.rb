# frozen_string_literal: true

# This object returns simple header for authentication
# Simple header is relatively unsafe, but can be useful for debug and development
# https://uploadcare.com/docs/api_reference/rest/requests_auth/#auth-simple

module Uploadcare
  class SimpleAuthHeader
    def self.call
      { 'Authorization': "Uploadcare.Simple #{PUBLIC_KEY}:#{SECRET_KEY}" }
    end
  end
end

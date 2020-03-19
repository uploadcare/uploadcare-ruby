# frozen_string_literal: true

module Uploadcare
  module Param
    # This object returns simple header for authentication
    # Simple header is relatively unsafe, but can be useful for debug and development
    class SimpleAuthHeader
      # @see https://uploadcare.com/docs/api_reference/rest/requests_auth/#auth-simple
      def self.call
        { 'Authorization': "Uploadcare.Simple #{Uploadcare.config.public_key}:#{Uploadcare.config.secret_key}" }
      end
    end
  end
end

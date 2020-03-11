# frozen_string_literal: true

require 'digest/md5'

module Uploadcare
  module Param
    # This object returns headers needed for authentication
    # This authentication method is more secure, but more tedious
    class SecureAuthHeader
      # @see https://uploadcare.com/docs/api_reference/rest/requests_auth/#auth-uploadcare
      def self.call(method: 'GET', body: '', content_type: 'application/json', uri: '')
        @method = method
        @body = body
        @content_type = content_type
        @uri = uri
        @date_for_header = self.timestamp
        {
          'Date': @date_for_header,
          'Authorization': "Uploadcare #{Uploadcare.configuration.public_key}:#{self.signature}"
        }
      end

      protected

      def self.signature
        content_md5 = Digest::MD5.hexdigest(@body)
        sign_string = [@method, content_md5, @content_type, @date_for_header, @uri].join("\n")
        digest = OpenSSL::Digest.new('sha1')
        OpenSSL::HMAC.hexdigest(digest, Uploadcare.configuration.secret_key, sign_string)
      end

      def self.timestamp
        Time.now.gmtime.strftime('%a, %d %b %Y %H:%M:%S GMT')
      end
    end
  end
end

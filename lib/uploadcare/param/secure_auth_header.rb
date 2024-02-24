# frozen_string_literal: true

require 'digest/md5'
require 'addressable/uri'

module Uploadcare
  module Param
    # This object returns headers needed for authentication
    # This authentication method is more secure, but more tedious
    class SecureAuthHeader
      class << self
        # @see https://uploadcare.com/docs/api_reference/rest/requests_auth/#auth-uploadcare
        def call(options = {})
          @method = options[:method]
          @body = options[:content] || ''
          @content_type = options[:content_type]
          @uri = make_uri(options)

          @date_for_header = timestamp
          {
            Date: @date_for_header,
            Authorization: "Uploadcare #{Uploadcare.config.public_key}:#{signature}"
          }
        end

        def signature
          content_md5 = Digest::MD5.hexdigest(@body)
          sign_string = [@method, content_md5, @content_type, @date_for_header, @uri].join("\n")
          digest = OpenSSL::Digest.new('sha1')
          OpenSSL::HMAC.hexdigest(digest, Uploadcare.config.secret_key, sign_string)
        end

        def timestamp
          Time.now.gmtime.strftime('%a, %d %b %Y %H:%M:%S GMT')
        end

        private

        def make_uri(options)
          if options[:params] && !options[:params].empty?
            uri = Addressable::URI.parse options[:uri]
            uri.query_values = uri.query_values(Array).to_a.concat(options[:params].to_a)
            uri.to_s
          else
            options[:uri]
          end
        end
      end
    end
  end
end

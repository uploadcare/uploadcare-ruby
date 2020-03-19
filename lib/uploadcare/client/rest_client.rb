# frozen_string_literal: true

require_relative 'rest_client'
require 'uploadcare/concern/error_handler'
require 'uploadcare/concern/throttle_handler'
require 'param/authentication_header'

module Uploadcare
  module Client
    # @abstract
    # General client for signed REST requests
    class RestClient < ApiStruct::Client
      include Uploadcare::Concerns::ErrorHandler
      include Uploadcare::Concerns::ThrottleHandler
      include Exception

      alias api_struct_delete delete
      alias api_struct_get get
      alias api_struct_post post
      alias api_struct_put put

      # Send request with authentication header
      #
      # Handle throttling as well
      def request(method: 'GET', uri:, **options)
        headers = Param::AuthenticationHeader.call(method: method.upcase, uri: uri, **options)
        handle_throttling do
          send('api_struct_' + method.downcase, path: remove_trailing_slash(uri),
                                                headers: headers, body: options[:content])
        end
      end

      def get(**options)
        request(method: 'GET', **options)
      end

      def post(**options)
        request(method: 'POST', **options)
      end

      def put(**options)
        request(method: 'PUT', **options)
      end

      def delete(**options)
        request(method: 'DELETE', **options)
      end

      def api_root
        Uploadcare.config.rest_api_root
      end

      def headers
        {
          'Content-type': 'application/json',
          'Accept': 'application/vnd.uploadcare-v0.5+json',
          'User-Agent': Uploadcare::Param::UserAgent.call
        }
      end

      private

      def remove_trailing_slash(str)
        str.gsub(%r{^\/}, '')
      end

      def default_params
        {}
      end
    end
  end
end

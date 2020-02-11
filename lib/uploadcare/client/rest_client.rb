# frozen_string_literal: true

require 'uploadcare/concerns/error_handler'

module Uploadcare
  # General client for signed REST requests
  class RestClient < ApiStruct::Client
    include Uploadcare::ErrorHandler
    rest_api 'files'

    alias api_struct_delete delete
    alias api_struct_get get
    alias api_struct_post post
    alias api_struct_put put

    # Send request with authentication header

    def request(method: 'GET', uri:, **options)
      headers = AuthenticationHeader.call(method: method.upcase, uri: uri, **options)
      send('api_struct_' + method.downcase, path: remove_trailing_slash(uri), headers: headers, body: options[:content])
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

    private

    def remove_trailing_slash(str)
      str.gsub(%r{^\/}, '')
    end
  end
end

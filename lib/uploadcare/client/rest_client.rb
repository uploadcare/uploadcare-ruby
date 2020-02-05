# frozen_string_literal: true

module Uploadcare
  # General client for signed REST requests
  class RestClient < ApiStruct::Client
    rest_api 'files'

    alias api_struct_delete delete
    alias api_struct_get get
    alias api_struct_post post
    alias api_struct_put put

    # Send request with authentication header

    def signed_request(method: 'GET', uri:, **options)
      headers = AuthenticationHeader.call(method: method.upcase, uri: uri, **options)
      send('api_struct_' + method.downcase, path: remove_trailing_slash(uri), headers: headers, body: options[:content])
    end

    def signed_get(**options)
      signed_request(method: 'GET', **options)
    end

    def signed_post(**options)
      signed_request(method: 'POST', **options)
    end

    def signed_put(**options)
      signed_request(method: 'PUT', **options)
    end

    def signed_delete(**options)
      signed_request(method: 'DELETE', **options)
    end

    private

    def remove_trailing_slash(str)
      str.gsub(%r{^\/}, '')
    end
  end
end

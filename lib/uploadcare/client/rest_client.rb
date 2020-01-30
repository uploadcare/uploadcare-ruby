# frozen_string_literal: true

module Uploadcare
  # General client for signed REST requests
  class RestClient < ApiStruct::Client
    rest_api 'files'

    alias _delete delete

    # Send request with authentication header

    def signed_request(method: 'GET', uri:, **options)
      headers = AuthenticationHeader.call(method: method.upcase, uri: uri, **options)
      method = '_delete' if method.casecmp('delete').zero?
      send(method.downcase, path: remove_trailing_slash(uri), headers: headers, body: options[:content])
    end

    private

    def remove_trailing_slash(str)
      str.gsub(%r{^\/}, '')
    end
  end
end

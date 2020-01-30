# frozen_string_literal: true

module Uploadcare
  # General client for signed REST requests
  class RestClient < ApiStruct::Client
    rest_api 'files'

    alias :_delete :delete

    # Send request with authentication header

    def signed_request(method: 'GET', uri: uri, **options)
      headers = AuthenticationHeader.call(method: method.upcase, uri: uri)
      method = '_delete' if method.downcase == 'delete'
      response = send(method.downcase, path: remove_trailing_slash(uri), headers: headers)
    end

    private

    def remove_trailing_slash(str)
      str.gsub(/^\//, '')
    end
  end
end

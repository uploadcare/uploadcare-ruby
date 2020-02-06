# frozen_string_literal: true

require 'uploadcare/concerns/error_handler'
require 'uploadcare/concerns/unthrottleable'

module Uploadcare
  # General client for signed REST requests
  class RestClient < ApiStruct::Client
    include Uploadcare::ErrorHandler
    include Uploadcare::Unthrottleable
    rest_api 'files'

    alias _delete delete

    # Send request with authentication header

    def signed_request(method: 'GET', uri:, **options)
      headers = AuthenticationHeader.call(method: method.upcase, uri: uri, **options)
      method = '_delete' if method.casecmp('delete').zero?
      unthrottleable { send(method.downcase, path: remove_trailing_slash(uri), headers: headers, body: options[:content]) }
    end

    private

    def remove_trailing_slash(str)
      str.gsub(%r{^\/}, '')
    end
  end
end

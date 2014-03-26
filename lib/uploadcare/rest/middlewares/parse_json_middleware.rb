require 'faraday'
require 'json'

module Uploadcare
  module Connections
    module Response
      class ParseJson < Faraday::Response::Middleware
        WHITESPACE_REGEX = /\A^\s*$\z/

        def parse(body)
          case body
          when WHITESPACE_REGEX, nil
            nil
          else
            JSON.parse(body)
          end
        end

        def on_complete(response)
          response[:body] = parse(response[:body]) if respond_to?(:parse) && !(response[:status] > 200) #!unparsable_status_codes.include?(response.status)
        end

        def unparsable_status_codes
          [204, 301, 302, 304]
        end
      end
    end
  end
end

Faraday::Response.register_middleware :parse_json => Uploadcare::Connections::Response::ParseJson
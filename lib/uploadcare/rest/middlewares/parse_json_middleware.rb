require 'faraday'
require 'json'

module Uploadcare
  module Connections
    module Response
      class ParseJson < Faraday::Response::Middleware
        WHITESPACE_REGEX = /\A^\s*$\z/

        ERROR_CODES = [400, 401, 403, 404, 406, 408, 422, 429, 500, 502, 503, 504]

        def parse(body)
          case body
          when WHITESPACE_REGEX, nil
            nil
          else
            JSON.parse(body)
          end
        end

        def on_complete(response)
          response[:body] = parse(response[:body]) if respond_to?(:parse) && !ERROR_CODES.include?(response[:status])
        end

        def unparsable_status_codes
          [204, 301, 302, 304]
        end
      end
    end
  end
end

Faraday::Response.register_middleware :uploadcare_parse_json => Uploadcare::Connections::Response::ParseJson

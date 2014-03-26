require 'faraday'

module Uploadcare
  module Connections
    module Response
      class RaiseError < Faraday::Response::Middleware
        def on_complete(response)
          @error_codes = [404, 403, 500, 503]
          
          if @error_codes.include?(response[:status])
            message = "HTTP code #{response[:status]}"
            fail(message)
          end
        end
      end
    end
  end
end

Faraday::Response.register_middleware :raise_error => Uploadcare::Connections::Response::RaiseError
require 'faraday'

module Uploadcare
  module Connections
    module Response
      class RaiseError < Faraday::Response::Middleware
        def on_complete(response)
          @error_codes = Uploadcare::Error.errors.keys
          @status = response[:status]

          if @error_codes.include?(@status)
            error = Uploadcare::Error.errors[@status].new
            fail(error)
          end
        end
      end
    end
  end
end

Faraday::Response.register_middleware :uploadcare_raise_error => Uploadcare::Connections::Response::RaiseError

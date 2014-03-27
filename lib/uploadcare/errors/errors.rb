module Uploadcare
  class Error < ::StandardError

    def self.define_error code, klass, message
      class_eval <<-EOD
        class #{klass} < self
          def initialize( message = nil )
            super( message || "HTTP #{code} - #{message}" )
          end
        end
      EOD
    end

    def self.errors
      @errors ||= {
        400 => Uploadcare::Error::RequestError::BadRequest,
        401 => Uploadcare::Error::RequestError::Unauthorized,
        403 => Uploadcare::Error::RequestError::Forbidden,
        404 => Uploadcare::Error::RequestError::NotFound,
        406 => Uploadcare::Error::RequestError::NotAcceptable,
        408 => Uploadcare::Error::RequestError::RequestTimeout,
        422 => Uploadcare::Error::RequestError::UnprocessableEntity,
        429 => Uploadcare::Error::RequestError::TooManyRequests,
        500 => Uploadcare::Error::ServerError::InternalServerError,
        502 => Uploadcare::Error::ServerError::BadGateway,
        503 => Uploadcare::Error::ServerError::ServiceUnavailable,
        504 => Uploadcare::Error::ServerError::GatewayTimeout,
      }
    end


    # Overall service error so you could escape it no matter what code is return

    # all 4xx error
    class RequestError < self;
      def initialize( message = nil )
        super( message || "HTTP 4xx - a request error occured." )
      end

      define_error 400, "BadRequest", "the request cannot be fulfilled due to bad syntax."
      define_error 401, "Unauthorized", "authentication is required and has failed or has not yet been provided."
      define_error 403, "Forbidden", "the request was a valid request, but the server is refusing to respond to it."
      define_error 404, "NotFound", "the requested resource could not be found."
      define_error 406, "NotAcceptable", "the requested resource is only capable of generating content"
      define_error 408, "RequestTimeout", "the server timed out waiting for the request."
      define_error 422, "UnprocessableEntity", "the request was well-formed but was unable to be followed due to semantic errors."
      define_error 429, "TooManyRequests", "too many requests in a given amount of time."
    end

    # all 5xx error
    class ServerError < self;
      def initialize( message = nil )
        super( message || "HTTP 5xx - a server error occured." )
      end

      define_error 500, "InternalServerError", "some error occured on server."
      define_error 502, "BadGateway", "received an invalid response from the upstream server."
      define_error 503, "ServiceUnavailable", "the server is currently unavailable."
      define_error 504, "GatewayTimeout", "the server did not receive a timely response from the upstream server."
    end

    # specific error
  end
end
# frozen_string_literal: true

module Uploadcare
  # Base error class for all Uploadcare errors
  class Error < StandardError
    attr_reader :response, :request

    def initialize(message = nil, response = nil, request = nil)
      super(message)
      @response = response
      @request = request
    end

    def status
      @response&.dig(:status)
    end

    def headers
      @response&.dig(:headers)
    end

    def body
      @response&.dig(:body)
    end
  end

  # Client errors (4xx)
  class ClientError < Error; end

  # Bad request error (400)
  class BadRequestError < ClientError; end

  # Authentication error (401)
  class AuthenticationError < ClientError; end

  # Forbidden error (403)
  class ForbiddenError < ClientError; end

  # Not found error (404)
  class NotFoundError < ClientError; end

  # Method not allowed error (405)
  class MethodNotAllowedError < ClientError; end

  # Not acceptable error (406)
  class NotAcceptableError < ClientError; end

  # Request timeout error (408)
  class RequestTimeoutError < ClientError; end

  # Conflict error (409)
  class ConflictError < ClientError; end

  # Gone error (410)
  class GoneError < ClientError; end

  # Unprocessable entity error (422)
  class UnprocessableEntityError < ClientError; end

  # Too many requests error (429)
  class RateLimitError < ClientError
    def retry_after
      headers&.dig('retry-after')&.to_i
    end
  end

  # Server errors (5xx)
  class ServerError < Error; end

  # Internal server error (500)
  class InternalServerError < ServerError; end

  # Not implemented error (501)
  class NotImplementedError < ServerError; end

  # Bad gateway error (502)
  class BadGatewayError < ServerError; end

  # Service unavailable error (503)
  class ServiceUnavailableError < ServerError; end

  # Gateway timeout error (504)
  class GatewayTimeoutError < ServerError; end

  # Network errors
  class NetworkError < Error; end

  # Connection failed error
  class ConnectionFailedError < NetworkError; end

  # Timeout error
  class TimeoutError < NetworkError; end

  # SSL error
  class SSLError < NetworkError; end

  # Configuration errors
  class ConfigurationError < Error; end

  # Invalid configuration error
  class InvalidConfigurationError < ConfigurationError; end

  # Missing configuration error
  class MissingConfigurationError < ConfigurationError; end

  # Request errors (already exists but enhancing)
  class RequestError < Error
    # Error mapping for HTTP status codes
    STATUS_ERROR_MAP = {
      400 => BadRequestError,
      401 => AuthenticationError,
      403 => ForbiddenError,
      404 => NotFoundError,
      405 => MethodNotAllowedError,
      406 => NotAcceptableError,
      408 => RequestTimeoutError,
      409 => ConflictError,
      410 => GoneError,
      422 => UnprocessableEntityError,
      429 => RateLimitError,
      500 => InternalServerError,
      501 => NotImplementedError,
      502 => BadGatewayError,
      503 => ServiceUnavailableError,
      504 => GatewayTimeoutError
    }.freeze

    def self.from_response(response, request = nil)
      status = response[:status]
      message = extract_message(response)

      error_class = STATUS_ERROR_MAP[status] ||
                    case status
                    when 400..499 then ClientError
                    when 500..599 then ServerError
                    else Error
                    end

      error_class.new(message, response, request)
    end

    def self.extract_message(response)
      body = response[:body]

      return "HTTP #{response[:status]}" unless body

      case body
      when Hash
        body['error'] || body['detail'] || body['message'] || "HTTP #{response[:status]}"
      when String
        body.empty? ? "HTTP #{response[:status]}" : body
      else
        "HTTP #{response[:status]}"
      end
    end
  end

  # Conversion errors (already exists but keeping for compatibility)
  class ConversionError < Error; end

  # Throttle errors (already exists but keeping for compatibility)
  class ThrottleError < RateLimitError; end

  # Auth errors (already exists but keeping for compatibility)
  class AuthError < AuthenticationError; end

  # Retry errors (already exists but keeping for compatibility)
  class RetryError < Error; end
end

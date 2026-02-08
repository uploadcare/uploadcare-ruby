# frozen_string_literal: true

module Uploadcare
  # Handles API errors and converts them to appropriate exceptions
  #
  # This module is included in client classes to provide consistent error handling
  # across all API requests. It parses error responses and raises typed exceptions.
  #
  # @example Including in a client class
  #   class MyClient
  #     include Uploadcare::ErrorHandler
  #   end
  module ErrorHandler
    # Handle a failed API request and raise an appropriate exception
    #
    # Parses the error response and raises a typed exception based on the HTTP status code.
    # Also handles Upload API errors which return status 200 with error details in the body.
    #
    # @param error [Faraday::Error] The error from the HTTP client
    # @raise [Uploadcare::Exception::InvalidRequestError] for 400 Bad Request
    # @raise [Uploadcare::Exception::NotFoundError] for 404 Not Found
    # @raise [Uploadcare::Exception::RequestError] for other error statuses
    def handle_error(error)
      response = error.response
      return raise Exception::RequestError, error.message if response.nil?

      catch_upload_errors(response)

      error_message = extract_error_message(response)
      raise_status_error(response[:status], error_message)
    end

    private

    # Extract error message from response body
    # @param response [Hash] Response hash with :body key
    # @return [String] Extracted error message
    # @api private
    def extract_error_message(response)
      parsed = JSON.parse(response[:body].to_s)
      parsed['detail'] || parsed.map { |k, v| "#{k}: #{v}" }.join('; ')
    rescue JSON::ParserError
      response[:body].to_s
    end

    # Raise appropriate error based on HTTP status code
    def raise_status_error(status, message)
      case status
      when 400 then raise Exception::InvalidRequestError, message
      when 404 then raise Exception::NotFoundError, message
      else raise Exception::RequestError, message
      end
    end

    # Upload API returns its errors with code 200, and stores its actual code and details within response message
    # This method detects that and raises an appropriate error
    def catch_upload_errors(response)
      return unless response[:status] == 200

      parsed_response = JSON.parse(response[:body].to_s)
      error = parsed_response['error'] if parsed_response.is_a?(Hash)
      raise Exception::RequestError, error if error
    end
  end
end

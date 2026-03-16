# frozen_string_literal: true

require 'json'

# Handles API errors and converts them to appropriate exceptions.
#
# This module is included in API base classes to provide consistent error handling
# across all API requests. It parses error responses and raises typed exceptions.
#
# @see Uploadcare::Api::Rest
# @see Uploadcare::Api::Upload
module Uploadcare::Internal::ErrorHandler
  # Handle a failed API request and raise an appropriate exception.
  #
  # Parses the error response and raises a typed exception based on the HTTP status code.
  # Also handles Upload API errors which return status 200 with error details in the body.
  #
  # @param error [Faraday::Error] The error from the HTTP client
  # @raise [Uploadcare::Exception::InvalidRequestError] for 400 Bad Request
  # @raise [Uploadcare::Exception::NotFoundError] for 404 Not Found
  # @raise [Uploadcare::Exception::ThrottleError] for 429 Too Many Requests
  # @raise [Uploadcare::Exception::RequestError] for other error statuses
  def handle_error(error)
    response = error.response
    return raise Uploadcare::Exception::RequestError, error.message if response.nil?

    catch_upload_errors(response)

    error_message = extract_error_message(response)
    raise_status_error(response, error_message)
  end

  private

  # Extract error message from response body.
  #
  # @param response [Hash] Response hash with :body key
  # @return [String] Extracted error message
  def extract_error_message(response)
    parsed = JSON.parse(response[:body].to_s)
    parsed['detail'] || parsed.map { |k, v| "#{k}: #{v}" }.join('; ')
  rescue JSON::ParserError
    response[:body].to_s
  end

  # Raise appropriate error based on HTTP status code.
  #
  # @param response [Hash] Response hash with :status key
  # @param message [String] Error message
  # @raise [Uploadcare::Exception::InvalidRequestError] for 400
  # @raise [Uploadcare::Exception::NotFoundError] for 404
  # @raise [Uploadcare::Exception::ThrottleError] for 429
  # @raise [Uploadcare::Exception::RequestError] for other statuses
  def raise_status_error(response, message)
    status = response.is_a?(Hash) ? response[:status] : response
    raise Uploadcare::Exception::InvalidRequestError, message if status == 400
    raise Uploadcare::Exception::NotFoundError, message if status == 404
    return raise_throttle_error(response, message) if status == 429

    raise Uploadcare::Exception::RequestError, message
  end

  # Upload API returns its errors with code 200, and stores its actual code and details
  # within the response message. This method detects that and raises an appropriate error.
  #
  # @param response [Hash] Response hash
  def catch_upload_errors(response)
    return unless response[:status] == 200

    parsed_response = JSON.parse(response[:body].to_s)
    error = parsed_response['error'] if parsed_response.is_a?(Hash)
    raise Uploadcare::Exception::RequestError, error if error
  rescue JSON::ParserError
    nil
  end

  # Raise a throttle error with retry-after timeout.
  #
  # @param response [Hash] Response hash
  # @param message [String] Error message
  # @raise [Uploadcare::Exception::ThrottleError]
  def raise_throttle_error(response, message)
    headers = response.is_a?(Hash) ? response[:headers] : nil
    retry_after = headers && (headers['retry-after'] || headers['Retry-After'])
    timeout = retry_after.to_f
    timeout = 10.0 if timeout <= 0
    raise Uploadcare::Exception::ThrottleError.new(timeout, message: message)
  end
end

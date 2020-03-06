# frozen_string_literal: true

require 'concerns/request_error'

module Uploadcare
  # Wrapper for responses
  # raises errors instead of returning monads
  module ErrorHandler
    def failure(response)
      catch_upload_errors(response)
      parsed_response = JSON.parse(response.body.to_s)
      raise RequestError, parsed_response['detail']
    rescue JSON::ParserError
      raise RequestError, response.status
    end

    def wrap(response)
      raise_throttling_error(response) if response.status == 429
      return failure(response) if response.status >= 300

      catch_upload_errors(response)
      success(response)
    end

    private

    def raise_throttling_error(response)
      retry_after = response.headers['Retry-After'].to_i + 1 || 11
      raise ThrottleError.new(retry_after), "Response throttled, retry #{retry_after} seconds later"
    end

    # Upload API returns its errors with code 200, and stores its actual code and details within response message
    # This methods detects that and raises apropriate error

    def catch_upload_errors(response)
      return unless response.code == 200

      parsed_response = JSON.parse(response.body.to_s)
      error = parsed_response['error'] if parsed_response.is_a?(Hash)
      raise RequestError, error if error
    end
  end
end

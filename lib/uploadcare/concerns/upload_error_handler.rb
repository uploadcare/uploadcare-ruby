# frozen_string_literal: true

module Uploadcare
  # Wrapper for responses
  # raises errors instead of returning monads
  module UploadErrorHandler
    def failure(response)
      catch_throttling_error(response)
      parsed_response = JSON.parse(response.body.to_s)
      raise RequestError, parsed_response['detail']
    rescue JSON::ParserError
      raise RequestError, response.status
    end

    private

    def catch_throttling_error(response)
      return unless response.code == 429

      retry_after = response.headers['Retry-After'].to_i + 1 || 11
      raise ThrottleError.new(retry_after), "Response throttled, retry #{retry_after} seconds later"
    end
  end
end

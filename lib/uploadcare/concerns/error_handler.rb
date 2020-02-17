# frozen_string_literal: true

module Uploadcare
  # Wrapper for responses
  # raises errors instead of returning monads
  module ErrorHandler
    def failure(response)
      parsed_response = JSON.parse(response.body.to_s)
      catch_throttling_error(response)
      raise RequestError.new(parsed_response['detail'])
    rescue JSON::ParserError => e
      raise RequestError.new(response.status)
    end

    private

    def catch_throttling_error(response)
      if response.code == 429
        retry_after = response.headers['Retry-After'].to_i + 1 || 11
        raise ThrottleError.new(retry_after), "Response throttled, retry #{retry_after} seconds later"
      end
    end
  end
end

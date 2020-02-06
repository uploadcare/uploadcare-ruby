# frozen_string_literal: true

module Uploadcare
  # Wrapper for responses
  # raises errors instead of returning monads
  module ErrorHandler
    def failure(response)
      parsed_response = JSON.parse(response.body.to_s)
      raise ThrottleError.new(parsed_response['detail']) if response.code == 429
      raise RequestError.new(parsed_response['detail'])
    rescue JSON::ParserError => e
      raise RequestError.new(response.status)
    end
  end
end

# frozen_string_literal: true

module Uploadcare
  module ErrorHandler
    include Exception

    # Catches failed API errors
    # Raises errors instead of returning falsey objects
    def handle_error(error)
      response = error.response
      catch_upload_errors(response)
      parsed_response = JSON.parse(response[:body].to_s)

      raise RequestError, parsed_response.to_s unless parsed_response.is_a?(Hash)
      raise RequestError, parsed_response['detail'] if parsed_response['detail']

      error_messages = parsed_response.map { |k, v| "#{k}: #{v}" }.join('; ')
      raise RequestError, error_messages
    rescue JSON::ParserError
      raise RequestError, response[:body].to_s
    end

    private

    # Upload API returns its errors with code 200, and stores its actual code and details within response message
    # This methods detects that and raises apropriate error
    def catch_upload_errors(response)
      return unless response[:status] == 200

      parsed_response = JSON.parse(response[:body].to_s)
      error = parsed_response['error'] if parsed_response.is_a?(Hash)
      raise RequestError, error if error && !error.to_s.empty?
    end
  end
end

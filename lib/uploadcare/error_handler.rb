# frozen_string_literal: true

module Uploadcare
  module ErrorHandler
    # Catches failed API errors
    # Raises errors instead of returning falsey objects
    def handle_error(error)
      response = error.response
      catch_upload_errors(response)
      
      # Use RequestError.from_response to create the appropriate error type
      raise Uploadcare::RequestError.from_response(response)
    end

    private

    # Upload API returns its errors with code 200, and stores its actual code and details within response message
    # This methods detects that and raises apropriate error
    def catch_upload_errors(response)
      return unless response[:status] == 200

      parsed_response = JSON.parse(response[:body].to_s)
      error = parsed_response['error'] if parsed_response.is_a?(Hash)
      raise Uploadcare::RequestError.new(error, response) if error
    end
  end
end

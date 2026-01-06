# frozen_string_literal: true

module Uploadcare
  module ErrorHandler
    # Catches failed API errors
    # Raises errors instead of returning falsey objects
    def handle_error(error)
      response = error.response
      catch_upload_errors(response)

      error_message = extract_error_message(response)
      raise_status_error(response[:status], error_message)
    end

    private

    # Extract error message from response body
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
    # This methods detects that and raises apropriate error
    def catch_upload_errors(response)
      return unless response[:status] == 200

      parsed_response = JSON.parse(response[:body].to_s)
      error = parsed_response['error'] if parsed_response.is_a?(Hash)
      raise Exception::RequestError, error if error
    end
  end
end

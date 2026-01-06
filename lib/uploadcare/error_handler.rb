# frozen_string_literal: true

module Uploadcare
  module ErrorHandler

    # Catches failed API errors
    # Raises errors instead of returning falsey objects
    def handle_error(error)
      response = error.response
      catch_upload_errors(response)
      parsed_response = JSON.parse(response[:body].to_s)
      error_message = parsed_response['detail'] || parsed_response.map { |k, v| "#{k}: #{v}" }.join('; ')
      
      # Raise specific error types based on HTTP status code
      case response[:status]
      when 400
        raise Exception::InvalidRequestError, error_message
      when 404
        raise Exception::NotFoundError, error_message
      else
        raise Exception::RequestError, error_message
      end
    rescue JSON::ParserError
      # For non-JSON responses, still check status code
      case response[:status]
      when 400
        raise Exception::InvalidRequestError, response[:body].to_s
      when 404
        raise Exception::NotFoundError, response[:body].to_s
      else
        raise Exception::RequestError, response[:body].to_s
      end
    end

    private

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

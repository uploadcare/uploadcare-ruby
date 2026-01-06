# frozen_string_literal: true

module Uploadcare
  module Exception
    # Standard error for invalid API responses
    class RequestError < StandardError; end
    
    # Specific error for invalid requests (400 Bad Request)
    class InvalidRequestError < RequestError; end
    
    # Specific error for not found resources (404 Not Found)
    class NotFoundError < RequestError; end
  end
  
  # Top-level aliases for backward compatibility
  InvalidRequestError = Exception::InvalidRequestError
  NotFoundError = Exception::NotFoundError
end

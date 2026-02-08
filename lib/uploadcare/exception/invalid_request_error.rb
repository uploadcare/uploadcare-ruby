# frozen_string_literal: true

module Uploadcare
  module Exception
    # Specific error for invalid requests (400 Bad Request)
    class InvalidRequestError < RequestError; end
  end
end

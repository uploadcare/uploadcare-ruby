# frozen_string_literal: true

module Uploadcare
  # Standard error for invalid API responses
  class RequestError < StandardError
  end

  class ThrottleError < StandardError
  end
end

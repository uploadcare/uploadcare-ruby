# frozen_string_literal: true

module Uploadcare
  # Standard error for invalid API responses
  class RequestError < StandardError
  end

  class ThrottleError < StandardError
    attr_reader :timeout
    def initialize(timeout=10.0)
      @timeout = timeout
    end
  end
end

# frozen_string_literal: true

module Uploadcare
  module Exception
    # Exception for throttled requests
    class ThrottleError < StandardError
      attr_reader :timeout
      # @param timeout [Float] Amount of seconds the request have been throttled for
      def initialize(timeout = 10.0)
        @timeout = timeout
      end
    end
  end
end

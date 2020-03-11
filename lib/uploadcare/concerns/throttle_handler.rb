# frozen_string_literal: true

module Uploadcare
  module Concerns
    # This module lets clients send request multiple times if request is throttled
    module ThrottleHandler
      # call given block. If ThrottleError is returned, it will wait and attempt again 4 more times
      # @yield executable block (HTTP request that may be throttled)
      def handle_throttling
        (Uploadcare.configuration.max_throttle_attempts - 1).times do
          begin
            return yield
          rescue(Exception::ThrottleError) => error
            wait_time = error.timeout
            sleep(wait_time)
            next
          end
        end
        yield
      end
    end
  end
end

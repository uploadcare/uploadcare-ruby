# frozen_string_literal: true

module Uploadcare
  module Concerns
    # This module lets clients send request multiple times if request is throttled
    module ThrottleHandler
      # call given block. If ThrottleError is returned, it will wait and attempt again 4 more times
      # @yield executable block (HTTP request that may be throttled)
      def handle_throttling
        (Uploadcare.config.max_throttle_attempts - 1).times do
          # rubocop:disable Style/RedundantBegin
          begin
            return yield
          rescue(Exception::ThrottleError) => e
            wait_time = e.timeout
            sleep(wait_time)
            next
          end
          # rubocop:enable Style/RedundantBegin
        end
        yield
      end
    end
  end
end

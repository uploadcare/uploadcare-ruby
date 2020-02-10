# frozen_string_literal: true

module Uploadcare
  # This module lets clients send request multiple times if request is throttled
  module ThrottleHandler
    ATTEMPTS = 5
    DEFAULT_WAIT = 11

    # call given block. If ThrottleError is returned, it will wait and attempt again 4 more times

    def handle_throttling
      (ATTEMPTS - 1).times do
        begin
          return yield
        rescue(ThrottleError) => error
          digits_in_message = error.message.match(/\d+/).to_s
          wait_time = digits_in_message.length > 0 ? digits_in_message.to_i : DEFAULT_WAIT
          sleep(wait_time)
          next
        end
      end
      yield
    end
  end
end

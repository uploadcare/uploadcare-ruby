# frozen_string_literal: true

module Uploadcare
  # This module lets clients send request multiple times if request is throttled
  module Unthrottleable
    ATTEMPTS = 5
    WAIT = 11

    # call given block. If ThrottleError is returned, it will wait and attempt again 4 more times

    def unthrottleable
      (ATTEMPTS - 1).times do
        begin
          return yield
        rescue(ThrottleError)
          sleep(WAIT)
          next
        end
      end
      yield
    end
  end
end

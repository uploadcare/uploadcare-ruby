# frozen_string_literal: true

# Handles API rate limiting (throttling) with automatic retry
#
# This module is included in client classes to provide automatic retry logic
# when the API returns a throttle error (HTTP 429). It respects the retry-after
# header and implements exponential backoff.
#
# @example Including in a client class
#   class MyClient
#     include Uploadcare::ThrottleHandler
#
#     def make_request
#       handle_throttling { connection.get('/endpoint') }
#     end
#   end
#
# @see https://uploadcare.com/docs/api_reference/rest/rate_limiting/
module Uploadcare::ThrottleHandler
  # Execute a block with automatic retry on throttle errors
  #
  # Wraps an HTTP request and automatically retries if a ThrottleError is raised.
  # The number of retry attempts is controlled by `max_throttle_attempts` configuration.
  # Sleep duration between retries is determined by the error's timeout value.
  #
  # @yield Block containing the HTTP request to execute
  # @return [Object] The result of the block execution
  # @raise [Uploadcare::Exception::ThrottleError] if max retry attempts exceeded
  #
  # @example
  #   handle_throttling do
  #     connection.get('/files/')
  #   end
  def handle_throttling(max_attempts: nil)
    attempts = max_attempts
    if attempts.nil?
      attempts = respond_to?(:config) ? config.max_throttle_attempts : Uploadcare.configuration.max_throttle_attempts
    end
    (attempts - 1).times do
      return yield
    rescue(Uploadcare::Exception::ThrottleError) => e
      sleep(e.timeout)
    end
    yield
  end
end

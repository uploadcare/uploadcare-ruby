# frozen_string_literal: true

# Handles API rate limiting (throttling) with automatic retry.
#
# This module is included in API base classes to provide automatic retry logic
# when the API returns a throttle error (HTTP 429). It respects the retry-after
# header (via ThrottleError#timeout) and implements exponential backoff.
#
# @see https://uploadcare.com/docs/api_reference/rest/rate_limiting/
module Uploadcare::Internal::ThrottleHandler
  # Execute a block with automatic retry on throttle errors.
  #
  # Wraps an HTTP request and automatically retries if a ThrottleError is raised.
  # Sleep duration between retries is determined by the error's timeout value
  # with exponential backoff.
  #
  # @param max_attempts [Integer, nil] Maximum retry attempts (defaults to config value)
  # @yield Block containing the HTTP request to execute
  # @return [Object] The result of the block execution
  # @raise [Uploadcare::Exception::ThrottleError] if max retry attempts exceeded
  def handle_throttling(max_attempts: nil)
    attempts = max_attempts
    if attempts.nil?
      attempts = respond_to?(:config) ? config.max_throttle_attempts : Uploadcare.configuration.max_throttle_attempts
    end
    attempts = attempts.to_i
    raise ArgumentError, 'max_attempts must be at least 1' if attempts < 1

    (attempts - 1).times do |index|
      return yield
    rescue Uploadcare::Exception::ThrottleError => e
      sleep(e.timeout * (2**index))
    end
    yield
  end
end

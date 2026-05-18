# frozen_string_literal: true

# Exception for throttled requests
class Uploadcare::Exception::ThrottleError < StandardError
  attr_reader :timeout

  # @param timeout [Float] Amount of seconds the request have been throttled for
  def initialize(message = nil, timeout: 10.0)
    super(message)
    @timeout = timeout
  end
end

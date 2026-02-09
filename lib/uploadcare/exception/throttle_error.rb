# frozen_string_literal: true

# Exception for throttled requests
class Uploadcare::Exception::ThrottleError < StandardError
  attr_reader :timeout

  # @param timeout [Float] Amount of seconds the request have been throttled for
  def initialize(timeout = 10.0)
    super
    @timeout = timeout
  end
end

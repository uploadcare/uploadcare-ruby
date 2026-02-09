# frozen_string_literal: true

# Result wrapper for success/error handling.
class Uploadcare::Result
  attr_reader :value, :error

  def initialize(value: nil, error: nil)
    @value = value
    @error = error
  end

  # Build a success result.
  #
  # @param value [Object]
  # @return [Uploadcare::Result]
  def self.success(value)
    new(value: value)
  end

  # Build a failure result.
  #
  # @param error [Object]
  # @return [Uploadcare::Result]
  def self.failure(error)
    new(error: error)
  end

  # Capture exceptions and wrap in Result.
  #
  # @return [Uploadcare::Result]
  def self.capture
    success(yield)
  rescue StandardError => e
    failure(e)
  end

  # Unwrap a Result or return the value as-is.
  #
  # @param value [Object]
  # @return [Object]
  def self.unwrap(value)
    value.is_a?(Uploadcare::Result) ? value.value! : value
  end

  def success?
    @error.nil?
  end

  def failure?
    !success?
  end

  # @return [Object] success value
  def success
    @value
  end

  # @return [Object] error value
  def failure
    @error
  end

  def value!
    raise @error if failure?

    @value
  end

  # @return [String, nil] error message
  def error_message
    return nil if @error.nil?

    @error.respond_to?(:message) ? @error.message : @error.to_s
  end
end

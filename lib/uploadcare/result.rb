# frozen_string_literal: true

module Uploadcare
  class Result
    attr_reader :value, :error

    def initialize(value: nil, error: nil)
      @value = value
      @error = error
    end

    def self.success(value)
      new(value: value)
    end

    def self.failure(error)
      new(error: error)
    end

    def self.capture
      success(yield)
    rescue StandardError => e
      failure(e)
    end

    def self.unwrap(value)
      value.is_a?(Result) ? value.value! : value
    end

    def success?
      @error.nil?
    end

    def failure?
      !success?
    end

    def success
      @value
    end

    def failure
      @error
    end

    def value!
      raise @error if failure?

      @value
    end

    def error_message
      return nil if @error.nil?

      @error.respond_to?(:message) ? @error.message : @error.to_s
    end
  end
end

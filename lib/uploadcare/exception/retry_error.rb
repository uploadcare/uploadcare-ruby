# frozen_string_literal: true

# Standard error to raise when needing to retry a request
class Uploadcare::Exception::RetryError < StandardError; end

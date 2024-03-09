# frozen_string_literal: true

module Uploadcare
  module Exception
    # Standard error to raise when needing to retry a request
    class RetryError < StandardError; end
  end
end

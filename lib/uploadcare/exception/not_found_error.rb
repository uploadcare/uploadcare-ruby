# frozen_string_literal: true

module Uploadcare
  module Exception
    # Specific error for not found resources (404 Not Found)
    class NotFoundError < RequestError; end
  end
end

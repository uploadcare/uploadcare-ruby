# frozen_string_literal: true

# Specific error for not found resources (404 Not Found)
class Uploadcare::Exception::NotFoundError < Uploadcare::Exception::RequestError; end

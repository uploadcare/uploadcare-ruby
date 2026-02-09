# frozen_string_literal: true

# Specific error for invalid requests (400 Bad Request)
class Uploadcare::Exception::InvalidRequestError < Uploadcare::Exception::RequestError; end

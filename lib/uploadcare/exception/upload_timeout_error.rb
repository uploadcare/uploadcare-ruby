# frozen_string_literal: true

# Raised when upload times out
class Uploadcare::Exception::UploadTimeoutError < Uploadcare::Exception::UploadError; end

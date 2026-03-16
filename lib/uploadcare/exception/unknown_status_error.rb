# frozen_string_literal: true

# Raised when upload status is unknown
class Uploadcare::Exception::UnknownStatusError < Uploadcare::Exception::UploadError; end

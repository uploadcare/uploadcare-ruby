# frozen_string_literal: true

module Uploadcare
  module Exception
    # General upload error
    class UploadError < StandardError; end

    # Raised when upload times out
    class UploadTimeoutError < UploadError; end

    # Raised when multipart upload fails
    class MultipartUploadError < UploadError; end

    # Raised when upload status is unknown
    class UnknownStatusError < UploadError; end
  end
end

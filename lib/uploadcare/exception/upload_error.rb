# frozen_string_literal: true

# General upload error
class Uploadcare::Exception::UploadError < StandardError; end

# Raised when upload times out
class Uploadcare::Exception::UploadTimeoutError < Uploadcare::Exception::UploadError; end

# Raised when multipart upload fails
class Uploadcare::Exception::MultipartUploadError < Uploadcare::Exception::UploadError; end

# Raised when upload status is unknown
class Uploadcare::Exception::UnknownStatusError < Uploadcare::Exception::UploadError; end

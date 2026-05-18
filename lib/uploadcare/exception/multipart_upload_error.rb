# frozen_string_literal: true

# Raised when multipart upload fails
class Uploadcare::Exception::MultipartUploadError < Uploadcare::Exception::UploadError; end

# frozen_string_literal: true

require 'concerns/request_error'

module Uploadcare
  # This object decides which of upload methods to use.
  # Returns either file or array of files
  class UploadAdapter
    extend Uploadcare::ThrottleHandler
    def self.call(object, **options)
      if big_file?(object)
        upload_big_file(object, **options)
      elsif file?(object)
        upload_file(object, **options)
      elsif object.is_a?(Array)
        upload_files(object, **options)
      elsif object.is_a?(String)
        upload_from_url(object, **options)
      else
        raise ArgumentError, "Expected input to be a file/Array/URL, given: `#{object}`"
      end
    end

    protected

    def self.upload_file(object, **options)
      response = UploadClient.new.upload_many([object], **options)
      handle_upload_errors(response)
      Entity::File.info(response.success.to_a.flatten[-1])
    end

    def self.upload_files(object, **options)
      response = handle_throttling { UploadClient.new.upload_many(object, **options) }
      handle_upload_errors(response)
      Hashie::Mash.new(files: response.success.map { |pair| { original_filename: pair[0], uuid: pair[1] } })
    end

    def self.upload_big_file(object, **_options)
      response = MultipartUploadClient.new.upload(object)
      handle_upload_errors(response)
      Entity::File.new(response.success)
    end

    def self.upload_from_url(object, **options)
      response = UploadClient.new.upload_from_url(object, **options)
      handle_upload_errors(response)
      Entity::Uploader.new(response.success)
    end

    def self.file?(object)
      object.respond_to?(:path) && ::File.exist?(object.path)
    end

    def self.big_file?(object)
      file?(object) && object.size >= Uploadcare.configuration.multipart_size_threshold
    end

    def self.handle_upload_errors(response)
      error = response.success[:error]
      raise(RequestError, error[:content]) if error
    end

    def self.handle_upload_errors(response)
      error = response.success[:error]
      raise(RequestError, error[:content]) if error
    end
  end
end

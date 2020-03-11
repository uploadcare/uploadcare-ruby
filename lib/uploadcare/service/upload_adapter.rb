# frozen_string_literal: true

module Uploadcare
  # This object decides which of upload methods to use.
  # Returns either file or array of files
  class UploadAdapter
    include Client
    extend Uploadcare::Concerns::ThrottleHandler
    # Choose an upload method
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

    def self.upload_file(file, **options)
      response = UploadClient.new.upload_many([file], **options)
      handle_upload_errors(response)
      Entity::File.info(response.success.to_a.flatten[-1])
    end

    def self.upload_files(arr, **options)
      response = handle_throttling { UploadClient.new.upload_many(arr, **options) }
      handle_upload_errors(response)
      Hashie::Mash.new(files: response.success.map { |pair| { original_filename: pair[0], uuid: pair[1] } })
    end

    def self.upload_big_file(file, **_options)
      response = MultipartUploadClient.new.upload(file)
      handle_upload_errors(response)
      Entity::File.new(response.success)
    end

    def self.upload_from_url(url, **options)
      response = UploadClient.new.upload_from_url(url, **options)
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

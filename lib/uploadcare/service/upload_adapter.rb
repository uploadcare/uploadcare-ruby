# frozen_string_literal: true

module Uploadcare
  # This object decides which of upload methods to use.
  # Returns either file or array of files
  class UploadAdapter
    def self.call(object, **options)
      case
      when big_file?(object)
        raise ArgumentError, 'multipart upload isnt implemented yet'
      when file?(object)
        upload_file(object, **options)
      when object.is_a?(Array)
        upload_files(object, **options)
      when object.is_a?(String)
        raise ArgumentError, 'uploading from strings is not implemented yet'
      else
        raise ArgumentError, "Expected input to be a file/Array/URL, given: `#{object}`"
      end
    end

    private

    def self.upload_file(object, **options)
      response = UploadClient.new.upload_many([object], **options)
      File.info(response.success.to_a.flatten[-1])
    end

    def self.upload_files(object, **options)
      response = UploadClient.new.upload_many(object, **options)
      Hashie::Mash.new(files: response.success.map { |pair| { original_filename: pair[0], uuid: pair[1] } })
    end

    def self.file?(object)
      object.respond_to?(:path) && ::File.exist?(object.path)
    end

    def self.big_file?(object)
      one_hundred_mb = 100 * 1024 * 1024
      file?(object) && object.size >= one_hundred_mb
    end
  end
end

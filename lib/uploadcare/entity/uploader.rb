# frozen_string_literal: true

module Uploadcare
  class Uploader < ApiStruct::Entity
    client_service UploadClient
    client_service MultipartUploadClient, only: :upload, prefix: :multipart

    attr_entity :files

    # Upload file or group of files from array, File, or url
    # object: Array, String or ::File
    #
    # options
    # store: (true|false) whether to store file on servers. Unstored files will be deleted in 2 weeks

    def self.upload(object, **options)
      UploadAdapter.call(object, options)
    end

    attr_entity :file, as: Uploadcare::File
  end
end

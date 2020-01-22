# frozen_string_literal: true

module Uploadcare
  # https://uploadcare.com/api-refs/upload-api/#tag/Upload
  class Uploader < ApiStruct::Entity
    client_service UploadClient

    attr_entity :files

    # Upload file or group of files from array, File, or url
    # object: Array, String or ::File
    #
    # options
    # store: (true|false) whether to store file on servers. Unstored files will be deleted in 2 weeks

    def self.upload(object, **options)
      UploadAdapter.call(object, options)
    end
  end
end

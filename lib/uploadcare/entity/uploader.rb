# https://uploadcare.com/api-refs/upload-api/#tag/Upload

module Uploadcare
  class Uploader < ApiStruct::Entity
    client_service UploadClient

    attr_entity :files
  end
end

# frozen_string_literal: true

# https://uploadcare.com/api-refs/upload-api/#tag/Upload

require 'client/chunks_client'

module Uploadcare
  class MultipartUploadClient < ApiStruct::Client
    upload_api

    def upload(object, store: false)
      response = upload_start(object, store: store)
      return response unless response.success[:parts] && response.success[:uuid]

      links = response.success[:parts]
      uuid = response.success[:uuid]
      ChunksClient.new.upload_chunks(object, links)
      upload_complete(uuid)
    end

    def upload_start(object, store: false)
      body = HTTP::FormData::Multipart.new(
        upload_params(store).merge(multiupload_metadata(object))
      )
      response = post(path: 'multipart/start/',
           headers: { 'Content-type': body.content_type },
           body: body)
    end

    def upload_complete(uuid)
      body = HTTP::FormData::Multipart.new(
        'UPLOADCARE_PUB_KEY': PUBLIC_KEY,
        'uuid': uuid
      )
      post(path: 'multipart/complete/', body: body, headers: { 'Content-type': body.content_type })
    end

    private

    def upload_params(store = false)
      {
        'UPLOADCARE_PUB_KEY': PUBLIC_KEY,
        'UPLOADCARE_STORE': (store == true) ? '1' : '0'
      }
    end

    def multiupload_metadata(file)
      file = HTTP::FormData::File.new(file)
      multiupload_metadata = {
        filename: file.filename,
        size: file.size,
        content_type: file.content_type
      }
    end

    def validate_file(object)
      ten_mb = 10 * 1024 * 1024
      if object.size < ten_mb
        raise(ArgumentError, "File is too small: #{object.size/1024.0/1024.0}/10mb")
      end
    end
  end
end

# frozen_string_literal: true

# https://uploadcare.com/api-refs/upload-api/#tag/Upload

require 'client/multipart_upload/chunks_client'

module Uploadcare
  # Client for multipart uploads
  class MultipartUploadClient < ApiStruct::Client
    include ErrorHandler
    include ThrottleHandler
    upload_api

    # Upload a big file by splitting it into parts and sending those parts into assigned buckets
    # object should be File

    def upload(object, store: false)
      response = upload_start(object, store: store)
      return response unless response.success[:parts] && response.success[:uuid]

      links = response.success[:parts]
      uuid = response.success[:uuid]
      MultipartUpload::ChunksClient.new.upload_chunks(object, links)
      upload_complete(uuid)
    end

    def upload_start(object, store: false)
      body = HTTP::FormData::Multipart.new(
        upload_params(store).merge(multiupload_metadata(object))
      )
      post(path: 'multipart/start/',
           headers: { 'Content-type': body.content_type },
           body: body)
    end

    def upload_complete(uuid)
      body = HTTP::FormData::Multipart.new(
        'UPLOADCARE_PUB_KEY': Uploadcare.configuration.public_key,
        'uuid': uuid
      )
      post(path: 'multipart/complete/', body: body, headers: { 'Content-type': body.content_type })
    end

    private

    def upload_params(store = 'auto')
      store = '1' if store == true
      store = '0' if store == false
      {
        'UPLOADCARE_PUB_KEY': Uploadcare.configuration.public_key,
        'UPLOADCARE_STORE': store
      }
    end

    def multiupload_metadata(file)
      file = HTTP::FormData::File.new(file)
      {
        filename: file.filename,
        size: file.size,
        content_type: file.content_type
      }
    end

    alias api_struct_post post
    def post(**args)
      handle_throttling { api_struct_post(**args) }
    end
  end
end

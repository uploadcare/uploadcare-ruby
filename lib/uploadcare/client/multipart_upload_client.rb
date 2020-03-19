# frozen_string_literal: true

require 'client/multipart_upload/chunks_client'
require_relative 'upload_client'

module Uploadcare
  module Client
    # Client for multipart uploads
    #
    # @see https://uploadcare.com/api-refs/upload-api/#tag/Upload
    class MultipartUploaderClient < UploadClient
      include MultipartUpload

      # Upload a big file by splitting it into parts and sending those parts into assigned buckets
      # object should be File
      def upload(object, store: false)
        response = upload_start(object, store: store)
        return response unless response.success[:parts] && response.success[:uuid]

        links = response.success[:parts]
        uuid = response.success[:uuid]
        ChunksClient.new.upload_chunks(object, links)
        upload_complete(uuid)
      end

      # Asks Uploadcare server to create a number of storage bin for uploads
      def upload_start(object, store: false)
        body = HTTP::FormData::Multipart.new(
          Param::Upload::UploadParamsGenerator.call(store).merge(multiupload_metadata(object))
        )
        post(path: 'multipart/start/',
             headers: { 'Content-type': body.content_type },
             body: body)
      end

      # When every chunk is uploaded, ask Uploadcare server to finish the upload
      def upload_complete(uuid)
        body = HTTP::FormData::Multipart.new(
          'UPLOADCARE_PUB_KEY': Uploadcare.config.public_key,
          'uuid': uuid
        )
        post(path: 'multipart/complete/', body: body, headers: { 'Content-type': body.content_type })
      end

      private

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
end

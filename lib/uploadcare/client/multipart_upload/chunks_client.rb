# frozen_string_literal: true

require 'parallel'

module Uploadcare
  module Client
    module MultipartUpload
      # This class splits file into chunks of set chunk_size
      # and uploads them into cloud storage.
      # Used for multipart uploads
      # @see https://uploadcare.com/api-refs/upload-api/#tag/Upload/paths/https:~1~1uploadcare.s3-accelerate.amazonaws.com~1%3C%3Cpresigned-url%3E/put
      class ChunksClient < ApiStruct::Client
        chunks_api
        CHUNK_SIZE = 5_242_880

        # In multiple threads, split file into chunks and upload those chunks into respective Amazon links
        # @param object [File]
        # @param links [Array] of strings; by default list of Amazon storage urls

        def upload_chunks(object, links)
          Parallel.each(0...links.count, in_threads: Uploadcare.configuration.upload_threads) do |link_id|
            offset = link_id * CHUNK_SIZE
            chunk = IO.read(object, CHUNK_SIZE, offset)
            upload_chunk(chunk, links[link_id])
          end
        end

        private

        def upload_chunk(chunk, link)
          put(path: link, body: chunk, headers: { 'Content-type': 'application/octet-stream' })
        end
      end
    end
  end
end

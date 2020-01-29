# frozen_string_literal: true

module Uploadcare
  # This class splits file into chunks of set chunk_size
  # and uploads them into cloud storage.
  # Used for multipart uploads
  # https://uploadcare.com/api-refs/upload-api/#tag/Upload/paths/https:~1~1uploadcare.s3-accelerate.amazonaws.com~1%3C%3Cpresigned-url%3E/put
  class ChunksClient < ApiStruct::Client
    chunks_api

    def upload_chunks(object, links)
      chunk_size = 5242880
      links.each do |link|
        chunk = object.read(chunk_size)
        upload_chunk(chunk, link)
      end
    end

    private

    def upload_chunk(chunk, link)
      put(path: link, body: chunk, headers: { 'Content-type': 'application/octet-stream' })
    end
  end
end

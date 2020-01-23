# frozen_string_literal: true

# https://uploadcare.com/api-refs/upload-api/#tag/Upload/paths/https:~1~1uploadcare.s3-accelerate.amazonaws.com~1%3C%3Cpresigned-url%3E/put

module Uploadcare
  class AmazonClient < ApiStruct::Client
    amazon_api

    def upload_parts(object, links)
      chunk_size = 5242880
      links.each do |link|
        chunk = object.read(chunk_size)
        put(path: link, body: chunk, headers: { 'Content-type': 'application/octet-stream' })
      end
    end
  end
end

# frozen_string_literal: true

require 'parallel'
require 'dry/monads'
require 'api_struct'

module Uploadcare
  module Client
    module MultipartUpload
      # This class splits file into chunks of set chunk_size
      # and uploads them into cloud storage.
      # Used for multipart uploads
      # @see https://uploadcare.com/api-refs/upload-api/#tag/Upload/paths/https:~1~1uploadcare.s3-accelerate.amazonaws.com~1%3C%3Cpresigned-url%3E/put
      class ChunksClient < ApiStruct::Client
        CHUNK_SIZE = 5_242_880

        # In multiple threads, split file into chunks and upload those chunks into respective Amazon links
        # @param object [File]
        # @param links [Array] of strings; by default list of Amazon storage urls
        def self.upload_chunks(object, links)
          Parallel.each(0...links.count, in_threads: Uploadcare.config.upload_threads) do |link_id|
            offset = link_id * CHUNK_SIZE
            chunk = File.read(object, CHUNK_SIZE, offset)
            new.upload_chunk(chunk, links[link_id])
            next unless block_given?

            yield(
              chunk_size: CHUNK_SIZE,
              object: object,
              offset: offset,
              link_id: link_id,
              links: links,
              links_count: links.count
            )
          end
        end

        def api_root
          ''
        end

        def headers
          {}
        end

        def upload_chunk(chunk, link)
          put(path: link, body: chunk, headers: { 'Content-Type': 'application/octet-stream' })
        end

        private

        def default_params
          {}
        end
      end
    end
  end
end

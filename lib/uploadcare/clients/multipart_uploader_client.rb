# frozen_string_literal: true

module Uploadcare
  # Client for multipart uploads
  #
  # @see https://uploadcare.com/api-refs/upload-api/#tag/Upload
  # Default chunk size for multipart uploads (10MB)
  class MultipartUploaderClient < UploadClient
    CHUNK_SIZE = 5_242_880

    # Upload a big file by splitting it into parts and sending those parts into assigned buckets
    # object should be File
    def upload(file:, request_options: {}, **options, &block)
      Uploadcare::Result.capture do
        response = Uploadcare::Result.unwrap(upload_start(file: file, request_options: request_options, **options))
        if response['parts'] && response['uuid']
          links = response['parts']
          uuid = response['uuid']
          upload_chunks(file, links, &block)
          Uploadcare::Result.unwrap(upload_complete(uuid: uuid, request_options: request_options))

          { 'uuid' => uuid }
        else
          response
        end
      end
    end

    # Asks Uploadcare server to create a number of storage bin for uploads
    def upload_start(file:, request_options: {}, **options)
      upload_params = multipart_start_params(file, options)

      post(path: '/multipart/start/', params: upload_params, request_options: request_options)
    end

    # When every chunk is uploaded, ask Uploadcare server to finish the upload
    def upload_complete(uuid:, request_options: {})
      params = {
        'UPLOADCARE_PUB_KEY' => config.public_key,
        'uuid' => uuid
      }

      post(path: '/multipart/complete/', params: params, request_options: request_options)
    end

    private

    # In multiple threads, split file into chunks and upload those chunks into respective Amazon links
    # @param object [File]
    # @param links [Array] of strings; by default list of Amazon storage urls
    def upload_chunks(file, links, &block)
      links.count.times do |link_index|
        process_chunk(file, links, link_index, &block)
      end
    end

    # Process a single chunk upload
    # @param object [File] File being uploaded
    # @param links [Array] Array of upload links
    # @param link_index [Integer] Index of the current chunk
    def process_chunk(file, links, link_index, &chunk_block)
      offset = link_index * CHUNK_SIZE
      chunk = ::File.read(file, CHUNK_SIZE, offset)
      Uploadcare::Result.unwrap(put(links[link_index], chunk))

      return unless chunk_block

      chunk_block.call(
        chunk_size: CHUNK_SIZE,
        object: file,
        offset: offset,
        link_index: link_index,
        links: links,
        links_count: links.count
      )
    rescue StandardError => e
      # Log error and re-raise for now - could implement retry logic here
      config.logger&.error("Chunk upload failed for link_id #{link_index}: #{e.message}")
      raise
    end

    # Build multipart form parameters for upload start
    def multipart_start_params(object, options)
      # Generate upload parameters (merged from UploadParamsGenerator functionality)
      upload_params = generate_upload_params(options)

      # Merge with file form data
      file_params = multipart_file_params(object)

      upload_params.merge(file_params)
    end

    def generate_upload_params(options = {})
      Uploadcare::Param::Upload::UploadParamsGenerator.call(options: options, config: config)
    end

    # Extract file parameters for multipart form
    def multipart_file_params(file)
      filename = file.respond_to?(:original_filename) ? file.original_filename : ::File.basename(file.path)
      mime_type = MIME::Types.type_for(file.path).first
      content_type = mime_type ? mime_type.content_type : 'application/octet-stream'

      {
        'filename' => filename,
        'size' => file.size.to_s,
        'content_type' => content_type
      }
    end

    # Override form_data_for to work with multipart uploads
    def form_data_for(file)
      multipart_file_params(file)
    end
  end
end

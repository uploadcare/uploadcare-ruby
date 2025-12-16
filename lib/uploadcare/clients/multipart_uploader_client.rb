# frozen_string_literal: true

require 'thread'
# require 'client/multipart_upload/chunks_client'
# require_relative 'upload_client'
module Uploadcare
  # Client for multipart uploads
  #
  # @see https://uploadcare.com/api-refs/upload-api/#tag/Upload
  # Default chunk size for multipart uploads (5MB)
  class MultipartUploaderClient < UploadClient
    CHUNK_SIZE = 5_242_880

    # Upload a big file by splitting it into parts and sending those parts into assigned buckets
    # object should be File
    def upload(object, options = {}, &block)
      response = upload_start(object, options)
      return response unless response['parts'] && response['uuid']

      links = response['parts']
      uuid = response['uuid']
      upload_chunks(object, links, &block)
      upload_complete(uuid)

      # Return the uuid in a consistent format
      { 'uuid' => uuid }
    end

    # Asks Uploadcare server to create a number of storage bin for uploads
    def upload_start(object, options = {})
      upload_params = multipart_start_params(object, options)

      post('/multipart/start/', upload_params)
    end

    # When every chunk is uploaded, ask Uploadcare server to finish the upload
    def upload_complete(uuid)
      params = {
        'UPLOADCARE_PUB_KEY' => Uploadcare.configuration.public_key,
        'uuid' => uuid
      }

      post('/multipart/complete/', params)
    end

    private

    # Split file into chunks and upload those chunks into respective Amazon links
    # @param object [File]
    # @param links [Array] of strings; by default list of Amazon storage urls
    def upload_chunks(object, links, &block)
      threads = []
      mutex = Mutex.new

      links.count.times do |link_index|
        threads << Thread.new do
          begin
            process_chunk(object, links, link_index) do |progress|
              mutex.synchronize { yield(progress) } if block_given?
            end
          rescue StandardError => e
            # Log error but continue with other chunks
            Uploadcare.configuration.logger&.error("Thread #{link_index} failed: #{e.message}")
            raise
          end
        end
      end

      # Wait for all threads to complete
      threads.each(&:join)
    end

    # Process a single chunk upload
    # @param object [File] File being uploaded
    # @param links [Array] Array of upload links
    # @param link_index [Integer] Index of the current chunk
    def process_chunk(object, links, link_index)
      offset = link_index * CHUNK_SIZE
      chunk = ::File.read(object, CHUNK_SIZE, offset)
      put(links[link_index], chunk)

      return unless block_given?

      yield(
        chunk_size: CHUNK_SIZE,
        object: object,
        offset: offset,
        link_index: link_index,
        links: links,
        links_count: links.count
      )
    rescue StandardError => e
      # Log error and re-raise for now - could implement retry logic here
      Uploadcare.configuration.logger&.error("Chunk upload failed for link_id #{link_index}: #{e.message}")
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

    # Generate upload parameters (integrated from UploadParamsGenerator)
    # @param options [Hash] upload options
    # @return [Hash] parameters for upload API
    # @see https://uploadcare.com/docs/api_reference/upload/request_based/
    def generate_upload_params(options = {})
      params = {
        'UPLOADCARE_PUB_KEY' => Uploadcare.configuration.public_key,
        'UPLOADCARE_STORE' => store_value(options[:store])
      }

      # Add signature if uploads are signed
      if Uploadcare.configuration.sign_uploads
        signature = generate_upload_signature
        params['signature'] = signature if signature
      end

      # Add metadata if provided
      params.merge!(generate_metadata_params(options[:metadata]))

      # Remove nil values
      params.compact
    end

    # Generate upload signature if signing is enabled
    # @return [String, nil] upload signature or nil if not available
    def generate_upload_signature
      # Check if SignatureGenerator is available
      if defined?(Uploadcare::Param::Upload::SignatureGenerator)
        Uploadcare::Param::Upload::SignatureGenerator.call
      else
        # Log warning that signing is enabled but generator is not available
        Uploadcare.configuration.logger&.warn('Upload signing is enabled but SignatureGenerator is not available')
        nil
      end
    rescue StandardError => e
      # Log error and continue without signature
      Uploadcare.configuration.logger&.error("Failed to generate upload signature: #{e.message}")
      nil
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

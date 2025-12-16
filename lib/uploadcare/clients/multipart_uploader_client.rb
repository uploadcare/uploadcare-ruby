# frozen_string_literal: true

require_relative 'multipart_upload_helpers'

module Uploadcare
  # Client for multipart uploads
  #
  # @see https://uploadcare.com/api-refs/upload-api/#tag/Upload
  class MultipartUploaderClient < UploadClient
    include MultipartUploadHelpers

    CHUNK_SIZE = 5_242_880 # 5MB
    MAX_CONCURRENT_UPLOADS = 4 # Control memory usage

    # Upload a big file by splitting it into parts
    # @param object [File] File to upload
    # @param options [Hash] Upload options
    # @return [Hash] Response with uuid
    def upload(object, options = {}, &block)
      response = upload_start(object, options)
      return response unless response['parts'] && response['uuid']

      links = response['parts']
      uuid = response['uuid']
      upload_chunks(object, links, &block)
      upload_complete(uuid)

      { 'uuid' => uuid }
    end

    # Start multipart upload
    def upload_start(object, options = {})
      upload_params = multipart_start_params(object, options)
      post('/multipart/start/', upload_params)
    end

    # Complete multipart upload
    def upload_complete(uuid)
      params = {
        'UPLOADCARE_PUB_KEY' => Uploadcare.configuration.public_key,
        'uuid' => uuid
      }
      post('/multipart/complete/', params)
    end

    private

    # Upload file chunks
    def upload_chunks(object, links, &block)
      work_queue = create_work_queue(links)
      threads = create_worker_threads(object, links, work_queue, &block)
      threads.each(&:join)
    end

    # Create work queue with chunk indices
    def create_work_queue(links)
      queue = Queue.new
      links.count.times { |i| queue.push(i) }
      queue
    end

    # Create worker threads for parallel uploads
    def create_worker_threads(object, links, work_queue, &block)
      mutex = Mutex.new
      thread_count = [MAX_CONCURRENT_UPLOADS, links.count].min

      Array.new(thread_count) do
        Thread.new do
          process_work_item(object, links, work_queue, mutex, &block)
        end
      end
    end

    # Process work items from queue
    def process_work_item(object, links, work_queue, mutex, &block)
      loop do
        link_index = work_queue.pop(true)
        process_chunk(object, links, link_index) do |progress|
          mutex.synchronize { block.call(progress) } if block
        end
      rescue ThreadError
        break # Queue empty
      rescue StandardError => e
        log_error("Thread failed for chunk: #{e.message}")
        raise
      end
    end

    # Process a single chunk upload
    def process_chunk(object, links, link_index)
      offset = link_index * CHUNK_SIZE
      chunk = ::File.read(object, CHUNK_SIZE, offset)
      put(links[link_index], chunk)

      yield(chunk_progress(object, link_index, links, offset)) if block_given?
    rescue StandardError => e
      log_error("Chunk upload failed for link_id #{link_index}: #{e.message}")
      raise
    end

    # Generate progress info for chunk
    def chunk_progress(object, link_index, links, offset)
      {
        chunk_size: CHUNK_SIZE,
        object: object,
        offset: offset,
        link_index: link_index,
        links: links,
        links_count: links.count
      }
    end

    # Log error message
    def log_error(message)
      Uploadcare.configuration.logger&.error(message)
    end

    # Override form_data_for to work with multipart uploads
    def form_data_for(file)
      multipart_file_params(file)
    end
  end
end

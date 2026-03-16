# frozen_string_literal: true

require 'mime/types'

# Handles the complete multipart upload workflow.
#
# Multipart upload is used for files larger than the multipart threshold (default: 100MB).
# The process:
# 1. Start upload → get UUID and presigned URLs
# 2. Upload file parts to presigned URLs (optionally in parallel)
# 3. Complete upload → finalize and get file info
#
# @example
#   mp = Uploadcare::Operations::MultipartUpload.new(upload_client: upload, config: config)
#   result = mp.upload(file: large_file, store: true, threads: 4)
module Uploadcare
  module Operations
    class MultipartUpload
      CHUNK_SIZE = 5_242_880 # 5MB default chunk size

      # @return [Uploadcare::Api::Upload] Upload API client
      attr_reader :upload_client

      # @return [Uploadcare::Configuration] Configuration
      attr_reader :config

      # @param upload_client [Uploadcare::Api::Upload] Upload API client
      # @param config [Uploadcare::Configuration] Configuration
      def initialize(upload_client:, config:)
        @upload_client = upload_client
        @config = config
      end

      # Execute the full multipart upload flow.
      #
      # @param file [File, IO] File to upload
      # @param options [Hash] Upload options (:store, :metadata, :threads, :part_size)
      # @param request_options [Hash] Request options
      # @yield [Hash] Progress callback with :uploaded, :total, :part, :total_parts
      # @return [Uploadcare::Result] Result containing { 'uuid' => '...' }
      def upload(file:, request_options: {}, **options, &block)
        Uploadcare::Result.capture do
          unless file.respond_to?(:read) && file.respond_to?(:path)
            raise ArgumentError, 'file must be a File or IO object with #read and #path'
          end

          file_size = file.respond_to?(:size) ? file.size : ::File.size(file.path)
          filename = file.respond_to?(:original_filename) ? file.original_filename : ::File.basename(file.path)
          content_type = MIME::Types.type_for(file.path).first&.content_type || 'application/octet-stream'

          start_response = Uploadcare::Result.unwrap(
            upload_client.files.multipart_start(
              filename: filename,
              size: file_size,
              content_type: content_type,
              request_options: request_options,
              **options
            )
          )

          uuid = start_response['uuid']
          presigned_urls = start_response['parts']

          part_size = options.fetch(:part_size, config.multipart_chunk_size)
          threads = options.fetch(:threads, 1)

          if threads > 1
            upload_parts_parallel(file, presigned_urls, part_size, threads, &block)
          else
            upload_parts_sequential(file, presigned_urls, part_size, &block)
          end

          Uploadcare::Result.unwrap(
            upload_client.files.multipart_complete(uuid: uuid, request_options: request_options)
          )

          { 'uuid' => uuid }
        end
      end

      private

      def upload_parts_sequential(file, presigned_urls, part_size, &block)
        total_size = file.respond_to?(:size) ? file.size : ::File.size(file.path)
        uploaded = 0

        presigned_urls.each_with_index do |presigned_url, index|
          file.seek(index * part_size)
          part_data = file.read(part_size)
          break if part_data.nil? || part_data.empty?

          upload_client.upload_part_to_url(presigned_url, part_data)
          uploaded += part_data.bytesize

          block&.call(uploaded: uploaded, total: total_size, part: index + 1, total_parts: presigned_urls.length)
        end
      end

      def upload_parts_parallel(file, presigned_urls, part_size, threads, &block)
        total_size = file.respond_to?(:size) ? file.size : ::File.size(file.path)
        uploaded = { value: 0 }
        mutex = Mutex.new
        queue = Queue.new
        errors = []
        file_path = file.path
        total_parts = presigned_urls.length

        presigned_urls.each_with_index { |url, index| queue << [url, index] }
        threads.times { queue << nil }

        workers = threads.times.map do
          Thread.new do
            run_parallel_worker(queue, file_path, part_size, total_size, total_parts, mutex, uploaded, errors, &block)
          end
        end

        workers.each(&:join)
        raise errors.first if errors.any?
      end

      def run_parallel_worker(queue, file_path, part_size, total_size, total_parts, mutex, uploaded, errors, &block)
        worker_file = ::File.open(file_path, 'rb')
        begin
          loop do
            job = begin
              queue.pop
            rescue ThreadError
              break
            end
            break if job.nil?

            presigned_url, index = job
            offset = index * part_size
            break if offset >= total_size

            worker_file.seek(offset)
            part_data = worker_file.read(part_size)
            break if part_data.nil? || part_data.empty?

            upload_client.upload_part_to_url(presigned_url, part_data)

            mutex.synchronize do
              uploaded[:value] += part_data.bytesize
              block&.call(uploaded: uploaded[:value], total: total_size, part: index + 1, total_parts: total_parts)
            end
          end
        rescue StandardError => e
          mutex.synchronize { errors << e }
        ensure
          worker_file.close
        end
      end
    end
  end
end

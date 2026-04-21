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
class Uploadcare::Operations::MultipartUpload
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
      prepared_file = Uploadcare::Internal::UploadIo.wrap(file)
      file_size = prepared_file.size
      filename = prepared_file.original_filename
      content_type = MIME::Types.type_for(prepared_file.path).first&.content_type || 'application/octet-stream'
      part_size, threads = normalize_upload_options(options)

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

      if threads > 1
        upload_parts_parallel(prepared_file, presigned_urls, part_size, threads, &block)
      else
        upload_parts_sequential(prepared_file, presigned_urls, part_size, &block)
      end

      Uploadcare::Result.unwrap(
        upload_client.files.multipart_complete(uuid: uuid, request_options: request_options)
      )

      { 'uuid' => uuid }
    ensure
      prepared_file&.close!
    end
  end

  private

  def normalize_upload_options(options)
    part_size = Integer(options.fetch(:part_size, config.multipart_chunk_size || CHUNK_SIZE))
    max_threads = Integer(config.upload_threads || 1)
    threads = Integer(options.fetch(:threads, max_threads))

    raise ArgumentError, 'part_size must be > 0' if part_size <= 0
    raise ArgumentError, 'upload_threads must be >= 1' if max_threads < 1
    raise ArgumentError, 'threads must be >= 1' if threads < 1
    raise ArgumentError, "threads must be <= #{max_threads}" if threads > max_threads

    [part_size, threads]
  end

  def upload_parts_sequential(file, presigned_urls, part_size, &block)
    total_size = file.respond_to?(:size) ? file.size : ::File.size(file.path)
    uploaded = 0

    presigned_urls.each_with_index do |presigned_url, index|
      file.seek(index * part_size)
      part_data = file.read(part_size)
      break if part_data.nil? || part_data.empty?

      upload_part(presigned_url, part_data)
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
    cancel = { value: false }
    file_path = file.path
    total_parts = presigned_urls.length

    presigned_urls.each_with_index { |url, index| queue << [url, index] }
    threads.times { queue << nil }

    worker_context = {
      queue: queue,
      file_path: file_path,
      part_size: part_size,
      total_size: total_size,
      total_parts: total_parts,
      mutex: mutex,
      uploaded: uploaded,
      errors: errors,
      cancel: cancel
    }

    workers = threads.times.map do
      Thread.new do
        run_parallel_worker(worker_context, &block)
      end
    end

    workers.each(&:join)
    raise errors.first if errors.any?
  end

  def run_parallel_worker(context, &block)
    ::File.open(context[:file_path], 'rb') do |worker_file|
      process_parallel_jobs(worker_file, context, &block)
    rescue StandardError => e
      record_parallel_error(context, e)
    end
  end

  def process_parallel_jobs(worker_file, context, &block)
    loop do
      job = context[:queue].pop
      break unless process_parallel_job(worker_file, context, job, &block)
    end
  end

  def process_parallel_job(worker_file, context, job)
    return false if job.nil? || context[:cancel][:value]

    presigned_url, index = job
    offset = index * context[:part_size]
    return false if offset >= context[:total_size]

    worker_file.seek(offset)
    part_data = worker_file.read(context[:part_size])
    return false if part_data.nil? || part_data.empty?

    upload_part(presigned_url, part_data)
    update_parallel_progress(context, index, part_data.bytesize) { |progress| yield(progress) if block_given? }
    true
  end

  def update_parallel_progress(context, index, bytesize)
    context[:mutex].synchronize do
      context[:uploaded][:value] += bytesize
      progress = {
        uploaded: context[:uploaded][:value],
        total: context[:total_size],
        part: index + 1,
        total_parts: context[:total_parts]
      }
      yield(progress)
    end
  end

  def record_parallel_error(context, error)
    context[:mutex].synchronize do
      context[:cancel][:value] = true
      context[:errors] << error
    end
  end

  def upload_part(presigned_url, part_data)
    upload_client.upload_part_to_url(
      presigned_url,
      part_data,
      max_retries: configured_max_upload_retries,
      timeout: configured_upload_timeout
    )
  end

  def configured_max_upload_retries
    value = config.max_upload_retries
    value.nil? ? 3 : Integer(value)
  end

  def configured_upload_timeout
    value = config.upload_timeout
    return nil if value.nil?

    Integer(value)
  end
end

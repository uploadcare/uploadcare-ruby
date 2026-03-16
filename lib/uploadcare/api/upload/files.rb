# frozen_string_literal: true

# Upload API endpoint for file upload operations.
#
# Supports direct upload, URL upload, multipart upload, and file info retrieval.
#
# @see https://uploadcare.com/api-refs/upload-api/
class Uploadcare::Api::Upload::Files
  # @return [Uploadcare::Api::Upload] Parent Upload client
  attr_reader :upload

  # @param upload [Uploadcare::Api::Upload] Parent Upload client
  def initialize(upload:)
    @upload = upload
  end

  # Upload a file directly (POST /base/).
  #
  # @param file [File, IO] File object to upload
  # @param options [Hash] Upload options (:store, :metadata, :signature, :expire)
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result] Upload response with file UUID
  # @raise [ArgumentError] if file is not a valid IO object
  # @see https://uploadcare.com/api-refs/upload-api/#operation/baseUpload
  def direct(file:, request_options: {}, **options)
    Uploadcare::Result.capture do
      prepared_file = Uploadcare::Internal::UploadIo.wrap(file)
      params = build_upload_params(prepared_file, options)
      Uploadcare::Result.unwrap(upload.post(path: 'base/', params: params, request_options: request_options))
    ensure
      prepared_file&.close!
    end
  end

  # Upload multiple files directly (POST /base/).
  #
  # @param files [Array<File, IO>] Files to upload
  # @param options [Hash] Upload options (:store, :metadata)
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result] Upload response hash mapping filenames to UUIDs
  # @see https://uploadcare.com/api-refs/upload-api/#operation/baseUpload
  def direct_many(files:, request_options: {}, **options)
    Uploadcare::Result.capture do
      raise ArgumentError, 'files must be an array' unless files.is_a?(Array)
      raise ArgumentError, 'files cannot be empty' if files.empty?

      prepared_files = files.map { |file| Uploadcare::Internal::UploadIo.wrap(file) }
      params = Uploadcare::Internal::UploadParamsGenerator.call(
        options: options, config: upload.config
      )
      prepared_files.each { |file| form_data_for(file, params) }
      Uploadcare::Result.unwrap(upload.post(path: '/base/', params: params, request_options: request_options))
    ensure
      prepared_files&.each(&:close!)
    end
  end

  # Upload a file from URL (POST /from_url/).
  #
  # @param source_url [String] URL of the file to upload
  # @param options [Hash] Upload options
  # @option options [Boolean] :async Return immediately with token (default: false)
  # @option options [String, Boolean] :store Whether to store the file
  # @option options [Hash] :metadata Custom metadata
  # @option options [Integer] :poll_interval Polling interval in seconds (default: 1)
  # @option options [Integer] :poll_timeout Max polling time in seconds (default: 300)
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result] Upload response (file info or token)
  # @see https://uploadcare.com/api-refs/upload-api/#operation/fromUrlUpload
  def from_url(source_url:, request_options: {}, **options)
    Uploadcare::Result.capture do
      validate_url(source_url)

      async_mode = options.fetch(:async, false)
      params = build_from_url_params(source_url, options)

      response = Uploadcare::Result.unwrap(
        upload.post(path: 'from_url/', params: params, request_options: request_options)
      )

      if async_mode
        response
      else
        poll_upload_status(token: response['token'], options: options, request_options: request_options)
      end
    end
  end

  # Get upload-from-URL status (GET /from_url/status/).
  #
  # @param token [String] Upload token from async upload
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result] Status response
  # @see https://uploadcare.com/api-refs/upload-api/#operation/fromUrlUploadStatus
  def from_url_status(token:, request_options: {})
    Uploadcare::Result.capture do
      raise ArgumentError, 'token cannot be empty' if token.to_s.strip.empty?

      Uploadcare::Result.unwrap(
        upload.get(path: 'from_url/status/', params: { token: token }, request_options: request_options)
      )
    end
  end

  # Start a multipart upload (POST /multipart/start/).
  #
  # @param filename [String] Original filename
  # @param size [Integer] File size in bytes
  # @param content_type [String] MIME type
  # @param options [Hash] Upload options (:store, :metadata, :part_size)
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result] Response with UUID and presigned URLs
  # @see https://uploadcare.com/api-refs/upload-api/#operation/multipartUploadStart
  def multipart_start(filename:, size:, content_type:, request_options: {}, **options)
    Uploadcare::Result.capture do
      raise ArgumentError, 'filename cannot be empty' if filename.to_s.strip.empty?
      raise ArgumentError, 'size must be a positive integer' unless size.is_a?(Integer) && size.positive?
      raise ArgumentError, 'content_type cannot be empty' if content_type.to_s.strip.empty?

      params = build_multipart_start_params(filename, size, content_type, options)
      Uploadcare::Result.unwrap(
        upload.post(path: 'multipart/start/', params: params, request_options: request_options)
      )
    end
  end

  # Complete a multipart upload (POST /multipart/complete/).
  #
  # @param uuid [String] Upload UUID from multipart_start
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result] Final file information
  # @see https://uploadcare.com/api-refs/upload-api/#operation/multipartUploadComplete
  def multipart_complete(uuid:, request_options: {})
    Uploadcare::Result.capture do
      raise ArgumentError, 'uuid cannot be empty' if uuid.to_s.strip.empty?

      params = {
        'UPLOADCARE_PUB_KEY' => upload.config.public_key,
        'uuid' => uuid
      }
      Uploadcare::Result.unwrap(
        upload.post(path: 'multipart/complete/', params: params, request_options: request_options)
      )
    end
  end

  # Get file info from Upload API (GET /info/).
  #
  # @param file_id [String] File UUID
  # @param request_options [Hash] Request options
  # @return [Uploadcare::Result] File information
  # @see https://uploadcare.com/api-refs/upload-api/#operation/filesInfo
  def info(file_id:, request_options: {})
    Uploadcare::Result.capture do
      raise ArgumentError, 'file_id cannot be empty' if file_id.to_s.strip.empty?

      Uploadcare::Result.unwrap(
        upload.get(path: 'info/', params: { pub_key: upload.config.public_key, file_id: file_id },
                   request_options: request_options)
      )
    end
  end

  private

  def validate_url(url)
    raise ArgumentError, 'URL cannot be empty' if url.to_s.strip.empty?

    uri = URI.parse(url)
    raise ArgumentError, 'URL must be HTTP or HTTPS' unless %w[http https].include?(uri.scheme)
  rescue URI::InvalidURIError => e
    raise ArgumentError, "Invalid URL: #{e.message}"
  end

  def build_upload_params(file, options)
    params = Uploadcare::Internal::UploadParamsGenerator.call(
      options: options, config: upload.config
    )
    form_data_for(file, params)
  end

  def form_data_for(file, params)
    file_path = file.path
    filename = file.respond_to?(:original_filename) ? file.original_filename : ::File.basename(file_path)
    mime = MIME::Types.type_for(file.path).first&.content_type || 'application/octet-stream'

    filename = "#{SecureRandom.random_number(100)}#{filename}" if params.key?(filename)

    params[filename] = Faraday::Multipart::FilePart.new(file_path, mime, filename)
    params
  end

  def build_from_url_params(source_url, options)
    params = {
      'pub_key' => upload.config.public_key,
      'source_url' => source_url
    }

    store = store_value(options[:store])
    params['store'] = store unless store.nil?

    params['check_URL_duplicates'] = options[:check_URL_duplicates].to_s if options[:check_URL_duplicates]
    params['save_URL_duplicates'] = options[:save_URL_duplicates].to_s if options[:save_URL_duplicates]

    metadata_params = generate_metadata_params(options[:metadata])
    params.merge!(metadata_params) if metadata_params.any?

    params.merge!(signature_params(options))
    params
  end

  def build_multipart_start_params(filename, size, content_type, options)
    part_size = options.fetch(:part_size, upload.config.multipart_chunk_size)

    params = {
      'UPLOADCARE_PUB_KEY' => upload.config.public_key,
      'filename' => filename,
      'size' => size.to_s,
      'content_type' => content_type,
      'part_size' => part_size.to_s
    }

    store = store_value(options[:store])
    params['UPLOADCARE_STORE'] = store unless store.nil?

    metadata_params = generate_metadata_params(options[:metadata])
    params.merge!(metadata_params) if metadata_params.any?

    params.merge!(signature_params(options))
    params
  end

  def poll_upload_status(token:, options: {}, request_options: {})
    poll_interval = options.fetch(:poll_interval, 1)
    poll_timeout = options.fetch(:poll_timeout, 300)
    start_time = Time.now

    loop do
      status = Uploadcare::Result.unwrap(from_url_status(token: token, request_options: request_options))

      case status['status']
      when 'success'
        return status
      when 'error'
        raise Uploadcare::Exception::UploadError, "Upload from URL failed: #{status['error']}"
      when 'waiting', 'progress'
        elapsed = Time.now - start_time
        if elapsed > poll_timeout
          raise Uploadcare::Exception::UploadTimeoutError,
                "Upload from URL polling timed out after #{poll_timeout} seconds"
        end

        sleep(poll_interval)
      else
        raise Uploadcare::Exception::UnknownStatusError, "Unknown upload status: #{status['status']}"
      end
    end
  end

  def store_value(store)
    return nil if store.nil?

    case store
    when true then '1'
    when false then '0'
    else store.to_s
    end
  end

  def generate_metadata_params(metadata = nil)
    return {} if metadata.nil? || !metadata.is_a?(Hash)

    metadata.each_with_object({}) do |(key, value), result|
      result["metadata[#{key}]"] = value.to_s
    end
  end

  def signature_params(options = {})
    return {} if options.nil?

    if options[:signature]
      params = { 'signature' => options[:signature] }
      params['expire'] = options[:expire].to_s if options[:expire]
      return params
    end

    return {} unless upload.config.sign_uploads

    result = Uploadcare::Internal::SignatureGenerator.call(config: upload.config)
    if result.is_a?(Hash)
      sig = result[:signature] || result['signature']
      exp = result[:expire] || result['expire']
      p = {}
      p['signature'] = sig if sig
      p['expire'] = exp if exp
      p
    else
      { 'signature' => result }
    end
  end
end

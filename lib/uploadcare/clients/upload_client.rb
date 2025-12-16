# frozen_string_literal: true

require 'faraday'
require 'faraday/multipart'
require 'mime/types'
require 'uri'

module Uploadcare
  # Client for Uploadcare Upload API
  #
  # Handles file uploads to Uploadcare using the Upload API.
  # Supports direct file uploads with multipart/form-data encoding.
  #
  # @see https://uploadcare.com/api-refs/upload-api/
  class UploadClient < RestClient
    # Initialize a new Upload API client
    #
    # @param config [Uploadcare::Configuration] configuration object
    # @return [Uploadcare::UploadClient] new upload client instance
    def initialize(config = Uploadcare.configuration)
      super
      @connection = Faraday.new(url: config.upload_api_root) do |conn|
        conn.request :multipart
        conn.request :url_encoded
        conn.adapter Faraday.default_adapter

        # Add response middleware
        conn.response :logger if ENV['DEBUG']
      end
    end

    # Perform a GET request to the Upload API
    #
    # @param path [String] API endpoint path
    # @param params [Hash] query parameters
    # @param headers [Hash] request headers
    # @return [Hash] parsed response
    def get(path, params = {}, headers = {})
      make_request(:get, path, params, headers)
    end

    # Perform a POST request to the Upload API
    #
    # @param path [String] API endpoint path
    # @param params [Hash] request body parameters
    # @param headers [Hash] request headers
    # @return [Hash] parsed response
    def post(path, params = {}, headers = {})
      make_request(:post, path, params, headers)
    end

    # Upload a file using the base upload endpoint (POST /base/)
    #
    # Uploads files up to 100MB using multipart/form-data encoding.
    # For larger files, use multipart upload instead.
    #
    # @param file [File, IO] file object to upload
    # @param options [Hash] upload options
    # @option options [String, Boolean] :store whether to store the file ('auto', '0', '1', true, false)
    # @option options [Hash] :metadata custom metadata key-value pairs
    # @option options [String] :signature upload signature for signed uploads
    # @option options [Integer] :expire signature expiration timestamp
    # @return [Hash] upload response with file UUID and metadata
    # @raise [ArgumentError] if file is not a File or IO object
    #
    # @example Upload a file with auto-store
    #   client = Uploadcare::UploadClient.new
    #   file = File.open('image.jpg')
    #   response = client.upload_file(file, store: 'auto')
    #   puts response['uuid']
    #
    # @example Upload with metadata
    #   client.upload_file(file, metadata: { subsystem: 'avatars', user_id: '123' })
    #
    # @see https://uploadcare.com/api-refs/upload-api/#operation/baseUpload
    def upload_file(file, options = {})
      raise ArgumentError, 'file must be a File or IO object' unless file.respond_to?(:read)

      params = build_upload_params(file, options)
      post('base/', params)
    end

    # Upload a file from a URL (POST /from_url/)
    #
    # Uploads a file from a remote URL. Supports both sync and async modes.
    # In sync mode, polls the status until the upload completes.
    # In async mode, returns immediately with a token for later status checking.
    #
    # @param source_url [String] URL of the file to upload
    # @param options [Hash] upload options
    # @option options [Boolean] :async use async mode (default: false)
    # @option options [String, Boolean] :store whether to store the file ('auto', '0', '1', true, false)
    # @option options [String] :check_URL_duplicates check for duplicate URLs ('0', '1')
    # @option options [String] :save_URL_duplicates save URL duplicates ('0', '1')
    # @option options [Hash] :metadata custom metadata key-value pairs
    # @option options [Integer] :poll_interval polling interval in seconds (default: 1)
    # @option options [Integer] :poll_timeout maximum polling time in seconds (default: 300)
    # @return [Hash] upload response with file UUID (sync) or token (async)
    # @raise [ArgumentError] if URL is invalid
    # @raise [Uploadcare::Exception::UploadTimeoutError] if polling times out
    #
    # @example Upload from URL (sync mode)
    #   client = Uploadcare::UploadClient.new
    #   response = client.upload_from_url('https://example.com/image.jpg')
    #   puts response['uuid']
    #
    # @example Upload from URL (async mode)
    #   response = client.upload_from_url('https://example.com/image.jpg', async: true)
    #   puts response['token']
    #
    # @see https://uploadcare.com/api-refs/upload-api/#operation/fromUrlUpload
    def upload_from_url(source_url, options = {})
      validate_url(source_url)

      async_mode = options.fetch(:async, false)
      params = build_from_url_params(source_url, options)

      response = post('from_url/', params)

      return response if async_mode

      poll_upload_status(response['token'], options)
    end

    # Get the status of a URL upload (GET /from_url/status/)
    #
    # Checks the status of an asynchronous URL upload using the token
    # returned from upload_from_url with async: true.
    #
    # @param token [String] upload token from async upload
    # @param options [Hash] polling options
    # @option options [Integer] :poll_interval polling interval in seconds (default: 1)
    # @option options [Integer] :poll_timeout maximum polling time in seconds (default: 300)
    # @return [Hash] status response with current upload state
    # @raise [ArgumentError] if token is invalid
    #
    # @example Check upload status
    #   client = Uploadcare::UploadClient.new
    #   status = client.upload_from_url_status('token-uuid')
    #   case status['status']
    #   when 'success'
    #     puts "Upload complete: #{status['uuid']}"
    #   when 'progress'
    #     puts "Upload in progress: #{status['progress']}%"
    #   when 'error'
    #     puts "Upload failed: #{status['error']}"
    #   end
    #
    # @see https://uploadcare.com/api-refs/upload-api/#operation/fromUrlUploadStatus
    def upload_from_url_status(token, _options = {})
      raise ArgumentError, 'token cannot be empty' if token.to_s.strip.empty?

      params = {
        token: token
      }
      get('from_url/status/', params)
    end

    # Start a multipart upload (POST /multipart/start/)
    #
    # Initiates a multipart upload for large files (>100MB).
    # Returns an upload UUID and presigned URLs for uploading file parts.
    #
    # @param filename [String] original filename
    # @param size [Integer] file size in bytes
    # @param content_type [String] MIME type of the file
    # @param options [Hash] upload options
    # @option options [Integer] :part_size size of each part in bytes (default: 5MB)
    # @option options [String, Boolean] :store whether to store the file ('auto', '0', '1', true, false)
    # @option options [Hash] :metadata custom metadata key-value pairs
    # @return [Hash] response with upload UUID and presigned URLs
    # @raise [ArgumentError] if required parameters are invalid
    #
    # @example Start multipart upload
    #   client = Uploadcare::UploadClient.new
    #   response = client.multipart_start('video.mp4', 500_000_000, 'video/mp4')
    #   uuid = response['uuid']
    #   parts = response['parts']
    #
    # @see https://uploadcare.com/api-refs/upload-api/#operation/multipartUploadStart
    def multipart_start(filename, size, content_type, options = {})
      raise ArgumentError, 'filename cannot be empty' if filename.to_s.strip.empty?
      raise ArgumentError, 'size must be a positive integer' unless size.is_a?(Integer) && size.positive?
      raise ArgumentError, 'content_type cannot be empty' if content_type.to_s.strip.empty?

      params = build_multipart_start_params(filename, size, content_type, options)
      post('multipart/start/', params)
    end

    # Upload a part of a multipart upload (PUT <presigned_url>)
    #
    # Uploads a single part of a multipart upload to the presigned URL
    # returned from multipart_start.
    #
    # @param presigned_url [String] presigned URL from multipart_start
    # @param part_data [String, IO] binary data for this part
    # @param options [Hash] upload options
    # @option options [Integer] :max_retries maximum number of retries (default: 3)
    # @return [Boolean] true if upload successful
    # @raise [ArgumentError] if presigned_url or part_data is invalid
    #
    # @example Upload a part
    #   client = Uploadcare::UploadClient.new
    #   part_data = file.read(5 * 1024 * 1024) # Read 5MB
    #   client.multipart_upload_part(presigned_url, part_data)
    #
    # @see https://uploadcare.com/api-refs/upload-api/#operation/multipartUploadPart
    def multipart_upload_part(presigned_url, part_data, options = {})
      raise ArgumentError, 'presigned_url cannot be empty' if presigned_url.to_s.strip.empty?
      raise ArgumentError, 'part_data cannot be nil' if part_data.nil?

      # For String data, check if empty. IO objects will be validated when read.
      raise ArgumentError, 'part_data cannot be empty' if part_data.respond_to?(:empty?) && part_data.empty?

      max_retries = options.fetch(:max_retries, 3)
      retries = 0

      begin
        upload_part_to_url(presigned_url, part_data)
        true
      rescue StandardError => e
        retries += 1
        raise "Failed to upload part after #{max_retries} retries: #{e.message}" unless retries < max_retries

        sleep(2**retries) # Exponential backoff
        retry
      end
    end

    # Complete a multipart upload (POST /multipart/complete/)
    #
    # Finalizes a multipart upload after all parts have been uploaded.
    # Returns the final file information.
    #
    # @param uuid [String] upload UUID from multipart_start
    # @return [Hash] file information including UUID and metadata
    # @raise [ArgumentError] if uuid is invalid
    #
    # @example Complete multipart upload
    #   client = Uploadcare::UploadClient.new
    #   response = client.multipart_complete('upload-uuid-1234')
    #   puts response['uuid']
    #
    # @see https://uploadcare.com/api-refs/upload-api/#operation/multipartUploadComplete
    def multipart_complete(uuid)
      raise ArgumentError, 'uuid cannot be empty' if uuid.to_s.strip.empty?

      params = {
        'UPLOADCARE_PUB_KEY' => config.public_key,
        'uuid' => uuid
      }
      post('multipart/complete/', params)
    end

    # Upload a large file using multipart upload (convenience method)
    #
    # Automatically handles the complete multipart upload flow:
    # 1. Start multipart upload
    # 2. Upload all parts (optionally in parallel)
    # 3. Complete the upload
    #
    # @param file [File, IO] file object to upload
    # @param options [Hash] upload options
    # @option options [String, Boolean] :store whether to store the file ('auto', '0', '1', true, false)
    # @option options [Hash] :metadata custom metadata key-value pairs
    # @option options [Integer] :part_size size of each part in bytes (default: 5MB)
    # @option options [Integer] :threads number of parallel upload threads (default: 1)
    # @return [Hash] file information including UUID and metadata
    # @raise [ArgumentError] if file is invalid
    #
    # @example Upload large file
    #   client = Uploadcare::UploadClient.new
    #   file = File.open('large_video.mp4', 'rb')
    #   response = client.multipart_upload(file, store: true)
    #   puts response['uuid']
    #
    # @example Upload with progress tracking
    #   client.multipart_upload(file, store: true) do |progress|
    #     puts "Uploaded #{progress[:uploaded]} / #{progress[:total]} bytes"
    #   end
    def multipart_upload(file, options = {}, &block)
      raise ArgumentError, 'file must be a File or IO object' unless file.respond_to?(:read)

      # Get file information
      file_size = file.respond_to?(:size) ? file.size : ::File.size(file.path)
      filename = file.respond_to?(:original_filename) ? file.original_filename : ::File.basename(file.path)
      content_type = MIME::Types.type_for(file.path).first&.content_type || 'application/octet-stream'

      # Start multipart upload
      start_response = multipart_start(filename, file_size, content_type, options)
      upload_uuid = start_response['uuid']
      presigned_urls = start_response['parts']

      # Upload parts
      part_size = options.fetch(:part_size, config.multipart_chunk_size)
      threads = options.fetch(:threads, 1)

      if threads > 1
        upload_parts_parallel(file, presigned_urls, part_size, threads, &block)
      else
        upload_parts_sequential(file, presigned_urls, part_size, &block)
      end

      # Complete the upload
      multipart_complete(upload_uuid)
    end

    # Create a file group from a list of file UUIDs (POST /group/)
    #
    # Groups serve a purpose of better organizing files in your Uploadcare projects.
    # You can create one from a set of files by using their UUIDs.
    #
    # @param files [Array<String>] array of file UUIDs to group
    # @param options [Hash] group creation options
    # @option options [String] :signature upload signature for signed uploads
    # @option options [Integer] :expire signature expiration timestamp
    # @return [Hash] group information with group UUID and file count
    # @raise [ArgumentError] if files array is empty or invalid
    #
    # @example Create a group
    #   client = Uploadcare::UploadClient.new
    #   files = ['uuid-1', 'uuid-2', 'uuid-3']
    #   response = client.create_group(files)
    #   puts response['id']  # => "group-uuid~3"
    #
    # @see https://uploadcare.com/api-refs/upload-api/#operation/createFilesGroup
    def create_group(files, options = {})
      raise ArgumentError, 'files must be an array' unless files.is_a?(Array)
      raise ArgumentError, 'files cannot be empty' if files.empty?

      params = { 'pub_key' => config.public_key }

      # Add each file with indexed parameter names (files[0], files[1], etc.)
      files.each_with_index do |file_uuid, index|
        # Extract UUID if file object is passed
        uuid = file_uuid.respond_to?(:uuid) ? file_uuid.uuid : file_uuid.to_s
        params["files[#{index}]"] = uuid
      end

      # Add signature if provided
      if options[:signature]
        params['signature'] = options[:signature]
        params['expire'] = options[:expire].to_s if options[:expire]
      end

      post('group/', params)
    end

    # Get information about a file group (GET /group/info/)
    #
    # Retrieves information about a file group without requiring a secret key.
    # This is useful for client-side applications.
    #
    # @param group_id [String] group UUID (with or without file count suffix)
    # @return [Hash] group information including files array
    # @raise [ArgumentError] if group_id is invalid
    #
    # @example Get group info
    #   client = Uploadcare::UploadClient.new
    #   info = client.group_info('group-uuid~3')
    #   puts info['files_count']  # => 3
    #
    # @see https://uploadcare.com/api-refs/upload-api/#operation/filesGroupInfo
    def group_info(group_id)
      raise ArgumentError, 'group_id cannot be empty' if group_id.to_s.strip.empty?

      params = {
        'pub_key' => config.public_key,
        'group_id' => group_id
      }
      get('group/info/', params)
    end

    # Get information about an uploaded file (GET /info/)
    #
    # Retrieves file information without requiring a secret key.
    # This is useful for client-side applications to get file metadata.
    #
    # @param file_id [String] file UUID
    # @return [Hash] file information including size, mime_type, etc.
    # @raise [ArgumentError] if file_id is invalid
    #
    # @example Get file info
    #   client = Uploadcare::UploadClient.new
    #   info = client.file_info('file-uuid')
    #   puts info['size']  # => 12345
    #   puts info['mime_type']  # => "image/jpeg"
    #
    # @see https://uploadcare.com/api-refs/upload-api/#operation/filesInfo
    def file_info(file_id)
      raise ArgumentError, 'file_id cannot be empty' if file_id.to_s.strip.empty?

      params = {
        'pub_key' => config.public_key,
        'file_id' => file_id
      }
      get('info/', params)
    end

    protected

    def make_request(method, path, params = {}, headers = {})
      handle_throttling do
        response = connection.public_send(method, path) do |req|
          prepare_request(req, method, path, params, headers)
        end
        handle_response(response)
      end
    rescue Faraday::Error => e
      handle_error(e)
    end

    # Handle response from Uploadcare API
    def handle_response(response)
      return handle_error_response(response) unless success_response?(response)

      parse_success_response(response)
    rescue JSON::ParserError => e
      handle_json_error(e, response)
    rescue Faraday::Error => e
      handle_faraday_error(e)
    end

    private

    # Validate URL format
    #
    # @param url [String] URL to validate
    # @raise [ArgumentError] if URL is invalid
    # @api private
    def validate_url(url)
      raise ArgumentError, 'URL cannot be empty' if url.to_s.strip.empty?

      uri = URI.parse(url)
      raise ArgumentError, 'URL must be HTTP or HTTPS' unless %w[http https].include?(uri.scheme)
    rescue URI::InvalidURIError => e
      raise ArgumentError, "Invalid URL: #{e.message}"
    end

    # Build parameters for URL upload
    #
    # @param source_url [String] URL to upload from
    # @param options [Hash] upload options
    # @return [Hash] upload parameters
    # @api private
    def build_from_url_params(source_url, options)
      params = {}

      params['pub_key'] = config.public_key
      params['source_url'] = source_url

      store = store_value(options[:store])
      params['store'] = store unless store.nil?

      params['check_URL_duplicates'] = options[:check_URL_duplicates].to_s if options[:check_URL_duplicates]
      params['save_URL_duplicates'] = options[:save_URL_duplicates].to_s if options[:save_URL_duplicates]

      metadata_params = generate_metadata_params(options[:metadata])
      params.merge!(metadata_params) if metadata_params.any?

      params
    end

    # Poll upload status until completion
    #
    # Polls the upload status endpoint until the upload completes or times out.
    #
    # @param token [String] upload token
    # @param options [Hash] polling options
    # @return [Hash] final status response
    # @raise [Uploadcare::Exception::UploadTimeoutError] if polling times out
    # @api private
    def poll_upload_status(token, options = {})
      poll_interval = options.fetch(:poll_interval, 1)
      poll_timeout = options.fetch(:poll_timeout, 300)
      start_time = Time.now

      loop do
        status = upload_from_url_status(token)

        case status['status']
        when 'success'
          return status
        when 'error'
          raise "Upload from URL failed: #{status['error']}"
        when 'waiting', 'progress'
          elapsed = Time.now - start_time
          raise "Upload from URL polling timed out after #{poll_timeout} seconds" if elapsed > poll_timeout

          sleep(poll_interval)
        else
          raise "Unknown upload status: #{status['status']}"
        end
      end
    end

    # Build parameters for multipart start
    #
    # @param filename [String] original filename
    # @param size [Integer] file size in bytes
    # @param content_type [String] MIME type
    # @param options [Hash] upload options
    # @return [Hash] multipart start parameters
    # @api private
    def build_multipart_start_params(filename, size, content_type, options)
      part_size = options.fetch(:part_size, config.multipart_chunk_size)

      params = {
        'UPLOADCARE_PUB_KEY' => config.public_key,
        'filename' => filename,
        'size' => size.to_s,
        'content_type' => content_type,
        'part_size' => part_size.to_s
      }

      store = store_value(options[:store])
      params['UPLOADCARE_STORE'] = store unless store.nil?

      metadata_params = generate_metadata_params(options[:metadata])
      params.merge!(metadata_params) if metadata_params.any?

      params
    end

    # Upload part data to presigned URL
    #
    # @param presigned_url [String] presigned URL
    # @param part_data [String, IO] binary data
    # @api private
    def upload_part_to_url(presigned_url, part_data)
      # Create a new connection for the presigned URL (different host)
      uri = URI.parse(presigned_url)
      conn = Faraday.new(url: "#{uri.scheme}://#{uri.host}") do |f|
        f.adapter Faraday.default_adapter
      end

      # Read data if it's an IO object
      data = part_data.respond_to?(:read) ? part_data.read : part_data

      response = conn.put(uri.request_uri) do |req|
        req.headers['Content-Type'] = 'application/octet-stream'
        req.body = data
      end

      raise "Failed to upload part: HTTP #{response.status}" unless response.status >= 200 && response.status < 300

      response
    end

    # Upload parts sequentially
    #
    # @param file [File, IO] file object
    # @param presigned_urls [Array<String>] presigned URLs
    # @param part_size [Integer] size of each part
    # @api private
    def upload_parts_sequential(file, presigned_urls, part_size, &block)
      total_size = file.respond_to?(:size) ? file.size : ::File.size(file.path)
      uploaded = 0

      presigned_urls.each_with_index do |presigned_url, index|
        file.seek(index * part_size)
        part_data = file.read(part_size)

        break if part_data.nil? || part_data.empty?

        multipart_upload_part(presigned_url, part_data)
        uploaded += part_data.bytesize

        block&.call({ uploaded: uploaded, total: total_size, part: index + 1, total_parts: presigned_urls.length })
      end
    end

    # Upload parts in parallel
    #
    # @param file [File, IO] file object
    # @param presigned_urls [Array<String>] presigned URLs
    # @param part_size [Integer] size of each part
    # @param threads [Integer] number of threads
    # @api private
    def upload_parts_parallel(file, presigned_urls, part_size, threads, &block)
      total_size = file.respond_to?(:size) ? file.size : ::File.size(file.path)
      uploaded = 0
      mutex = Mutex.new
      queue = Queue.new

      # Read all parts into memory (for thread safety)
      parts = []
      presigned_urls.each_with_index do |presigned_url, index|
        file.seek(index * part_size)
        part_data = file.read(part_size)

        break if part_data.nil? || part_data.empty?

        parts << { url: presigned_url, data: part_data, index: index }
      end

      # Add parts to queue
      parts.each { |part| queue << part }

      # Create worker threads
      workers = threads.times.map do
        Thread.new do
          until queue.empty?
            part = begin
              queue.pop(true)
            rescue StandardError
              nil
            end
            next unless part

            multipart_upload_part(part[:url], part[:data])

            mutex.synchronize do
              uploaded += part[:data].bytesize
              block&.call({ uploaded: uploaded, total: total_size, part: part[:index] + 1,
                            total_parts: parts.length })
            end
          end
        end
      end

      # Wait for all threads to complete
      workers.each(&:join)
    end

    def success_response?(response)
      response.status >= 200 && response.status < 300
    end

    def handle_error_response(response)
      raise "Upload API error: #{response.status} #{response.body}"
    end

    def parse_success_response(response)
      return {} if response.body.nil? || response.body.strip.empty?

      JSON.parse(response.body)
    end

    def handle_json_error(error, response)
      Uploadcare.configuration.logger&.error("Invalid JSON response: #{error.message}")
      success_response?(response) ? {} : response.body
    end

    # Convert store option to API format
    #
    # @param store [Boolean, String, nil] store option value
    # @return [String, nil] formatted store value ('0', '1', 'auto', or nil)
    # @api private
    def store_value(store)
      return nil if store.nil?

      case store
      when true
        '1'
      when false
        '0'
      else
        store.to_s
      end
    end

    # Generate metadata parameters for upload
    #
    # Converts a metadata hash into the format expected by the Upload API.
    # Each key-value pair becomes a parameter named "metadata[key]".
    #
    # @param metadata [Hash, nil] metadata hash with string or symbol keys
    # @return [Hash] formatted metadata parameters
    # @api private
    #
    # @example
    #   generate_metadata_params({ subsystem: 'avatars', user_id: '123' })
    #   # => { "metadata[subsystem]" => "avatars", "metadata[user_id]" => "123" }
    def generate_metadata_params(metadata = nil)
      return {} if metadata.nil? || !metadata.is_a?(Hash)

      metadata.each_with_object({}) do |(key, value), result|
        result["metadata[#{key}]"] = value.to_s
      end
    end

    # Handle Faraday-specific errors
    def handle_faraday_error(error)
      raise "HTTP #{error.response[:status]}: #{error.response[:body]}" if error.response

      raise "Network error: #{error.message}"
    end

    def form_data_for(file, params)
      file_path = file.path
      filename = file.original_filename if file.respond_to?(:original_filename)
      filename ||= ::File.basename(file_path)
      mime_type = MIME::Types.type_for(file.path).first
      mime_type ? mime_type.content_type : 'application/octet-stream'

      # if filename already exists, add a random number to the filename
      # to avoid overwriting the file
      filename = "#{SecureRandom.random_number(100)}#{filename}" if params.key?(filename)

      params[filename] = Faraday::Multipart::FilePart.new(
        file_path,
        mime_type,
        filename
      )

      params
    end

    def prepare_request(req, method, path, params, headers)
      upcase_method_name = method.to_s.upcase
      uri = path
      uri = build_request_uri(path, params, upcase_method_name) if upcase_method_name == 'GET'

      prepare_headers(req, upcase_method_name, uri, headers)
      prepare_body_or_params(req, upcase_method_name, params)
    end

    def prepare_headers(req, method, uri, headers)
      req.headers.merge!(authenticator.headers(method, uri)) unless %w[POST PUT].include?(method)
      req.headers.merge!(headers)
    end

    def prepare_body_or_params(req, method, params)
      if method == 'GET'
        req.params.update(params) unless params.empty?
      else
        # For POST/PUT, set body (Faraday middleware will handle encoding)
        req.body = params unless params.empty?
      end
    end

    # Build parameters for file upload
    #
    # Constructs the complete parameter set for a file upload request,
    # including authentication, storage options, metadata, and file data.
    #
    # @param file [File, IO] file object to upload
    # @param options [Hash] upload options
    # @return [Hash] complete upload parameters
    # @api private
    def build_upload_params(file, options)
      params = {}

      # Add public key first
      params['UPLOADCARE_PUB_KEY'] = config.public_key

      # Add store parameter
      store = store_value(options[:store])
      params['UPLOADCARE_STORE'] = store unless store.nil?

      # Add metadata
      metadata_params = generate_metadata_params(options[:metadata])
      params.merge!(metadata_params) if metadata_params.any?

      # Add signature if provided
      if options[:signature]
        params['signature'] = options[:signature]
        params['expire'] = options[:expire].to_s if options[:expire]
      end

      # Add file data last
      form_data_for(file, params)
    end
  end
end

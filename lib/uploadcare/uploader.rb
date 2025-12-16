# frozen_string_literal: true

module Uploadcare
  # High-level upload interface with smart detection
  #
  # Provides a simple, unified interface for uploading files to Uploadcare.
  # Automatically detects the best upload method based on the source type and file size.
  #
  # @example Upload a file
  #   file = Uploadcare::Uploader.upload('path/to/file.jpg', store: true)
  #
  # @example Upload from URL
  #   file = Uploadcare::Uploader.upload('https://example.com/image.jpg', store: true)
  #
  # @example Upload with progress tracking
  #   Uploadcare::Uploader.upload('large_file.mp4', store: true) do |progress|
  #     puts "#{progress[:percentage]}% complete"
  #   end
  module Uploader
    class << self
      # Upload a file with automatic method detection
      #
      # Automatically detects the best upload method:
      # - URLs (http/https) → upload_from_url
      # - Files < 10MB → upload_file (base upload)
      # - Files ≥ 10MB → multipart_upload
      #
      # @param source [String, File, IO] file path, URL, File object, or IO stream
      # @param options [Hash] upload options
      # @option options [String, Boolean] :store whether to store the file ('auto', '0', '1', true, false)
      # @option options [Hash] :metadata custom metadata key-value pairs
      # @option options [Integer] :threads number of parallel upload threads for multipart (default: 1)
      # @yield [progress] optional progress callback for multipart uploads
      # @yieldparam progress [Hash] progress information with :uploaded, :total, :percentage keys
      # @return [Hash] upload response with file UUID and metadata
      # @raise [ArgumentError] if source is invalid
      #
      # @example Upload a local file
      #   response = Uploadcare::Uploader.upload('photo.jpg', store: true)
      #   puts response['uuid']
      #
      # @example Upload from URL
      #   response = Uploadcare::Uploader.upload('https://example.com/image.jpg')
      #
      # @example Upload with progress
      #   Uploadcare::Uploader.upload('video.mp4', store: true) do |progress|
      #     puts "#{progress[:percentage]}% complete"
      #   end
      def upload(source, options = {}, &block)
        raise ArgumentError, 'source cannot be nil' if source.nil?

        client = UploadClient.new

        # Detect source type and choose upload method
        if url?(source)
          upload_from_url_wrapper(client, source, options)
        elsif file_or_io?(source)
          upload_file_wrapper(client, source, options, &block)
        elsif string_path?(source)
          upload_path_wrapper(client, source, options, &block)
        else
          raise ArgumentError, "Unsupported source type: #{source.class}"
        end
      end

      # Upload multiple files in batch
      #
      # Uploads multiple files and returns an array of results.
      # Individual file failures don't stop the batch.
      #
      # @param sources [Array<String, File, IO>] array of file paths, URLs, File objects, or IO streams
      # @param options [Hash] upload options applied to all files
      # @option options [String, Boolean] :store whether to store the files
      # @option options [Hash] :metadata custom metadata for all files
      # @option options [Integer] :parallel number of files to upload in parallel (default: 1)
      # @yield [result] optional callback for each completed upload
      # @yieldparam result [Hash] result with :source, :success, :response, :error keys
      # @return [Array<Hash>] array of upload results
      #
      # @example Upload multiple files
      #   files = ['photo1.jpg', 'photo2.jpg', 'photo3.jpg']
      #   results = Uploadcare::Uploader.upload_files(files, store: true)
      #   results.each do |result|
      #     if result[:success]
      #       puts "Uploaded: #{result[:response]['uuid']}"
      #     else
      #       puts "Failed: #{result[:error]}"
      #     end
      #   end
      def upload_files(sources, options = {}, &block)
        raise ArgumentError, 'sources must be an array' unless sources.is_a?(Array)
        raise ArgumentError, 'sources cannot be empty' if sources.empty?

        parallel = options.delete(:parallel) || 1

        if parallel > 1
          upload_files_parallel(sources, options, parallel, &block)
        else
          upload_files_sequential(sources, options, &block)
        end
      end

      private

      # Check if source is a URL
      def url?(source)
        source.is_a?(String) && source.match?(%r{^https?://})
      end

      # Check if source is a File or IO object
      def file_or_io?(source)
        source.respond_to?(:read)
      end

      # Check if source is a file path string
      def string_path?(source)
        source.is_a?(String)
      end

      # Upload from URL wrapper
      def upload_from_url_wrapper(client, url, options)
        client.upload_from_url(url, options)
      end

      # Upload file/IO wrapper with size detection
      def upload_file_wrapper(client, file, options, &block)
        file_size = file.respond_to?(:size) ? file.size : ::File.size(file.path)

        # Use multipart for files >= 10MB
        if file_size >= 10_000_000
          client.multipart_upload(file, options) do |progress|
            block&.call(progress.merge(percentage: (progress[:uploaded].to_f / progress[:total] * 100).round(2)))
          end
        else
          client.upload_file(file, options)
        end
      end

      # Upload file path wrapper
      def upload_path_wrapper(client, path, options, &block)
        raise ArgumentError, "File not found: #{path}" unless ::File.exist?(path)

        ::File.open(path, 'rb') do |file|
          upload_file_wrapper(client, file, options, &block)
        end
      end

      # Upload files sequentially
      def upload_files_sequential(sources, options, &block)
        results = []

        sources.each do |source|
          result = upload_single_with_error_handling(source, options)
          results << result
          block&.call(result)
        end

        results
      end

      # Upload files in parallel
      def upload_files_parallel(sources, options, parallel, &block)
        results = []
        mutex = Mutex.new
        queue = Queue.new

        sources.each { |source| queue << source }

        threads = parallel.times.map do
          Thread.new do
            until queue.empty?
              source = begin
                queue.pop(true)
              rescue StandardError
                nil
              end
              next unless source

              result = upload_single_with_error_handling(source, options)

              mutex.synchronize do
                results << result
                block&.call(result)
              end
            end
          end
        end

        threads.each(&:join)
        results
      end

      # Upload single file with error handling
      def upload_single_with_error_handling(source, options)
        # Get source identifier for reporting
        source_id = if source.is_a?(String)
                      source
                    elsif source.respond_to?(:path)
                      source.path
                    else
                      source.to_s
                    end

        {
          source: source_id,
          success: true,
          response: upload(source, options),
          error: nil
        }
      rescue StandardError => e
        {
          source: source_id || source,
          success: false,
          response: nil,
          error: e.message
        }
      end
    end
  end
end

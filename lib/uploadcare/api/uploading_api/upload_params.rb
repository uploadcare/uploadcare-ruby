require 'uri'
require 'mime/types'

module Uploadcare
  module UploadingApi
    class UploadParams
      def initialize(global_options, request_options)
        @global_options = global_options
        @request_options = request_options
      end

      def for_url_upload(url)
        {
          source_url: parse_url(url),
          pub_key: public_key,
          store: store
        }.reject { |k, v| v.nil? }
      end

      def for_file_upload(files)
        {
          UPLOADCARE_PUB_KEY: public_key,
          UPLOADCARE_STORE: store
        }.reject { |k, v| v.nil? }.merge(file_params(files))
      end

      private

      attr_reader :global_options, :request_options

      def public_key
        global_options[:public_key]
      end

      def store
        mapping = { true => 1, false => 0, auto: 'auto' }

        global_value = global_options[:store_files_upon_uploading]
        per_request_value = request_options[:store]

        mapping[per_request_value] || mapping[global_value]
      end

      def file_params(files)
        Hash[files.map.with_index { |file, i| ["file[#{i}]", build_upload_io(file)] }]
      end

      def parse_url(url)
        uri = URI.parse(url)

        unless uri.is_a?(URI::HTTP) # will also be true for https
          raise ArgumentError, 'invalid url was given'
        end

        uri
      end

      def build_upload_io(file)
        unless file.is_a?(File)
          raise ArgumentError, "expected File object, #{file} given"
        end

        Faraday::UploadIO.new file.path, extract_mime_type(file)
      end

      def extract_mime_type file
        types = MIME::Types.of(file.path)
        types[0].content_type
      end
    end
  end
end

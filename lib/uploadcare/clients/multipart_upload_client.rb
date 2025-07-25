# frozen_string_literal: true

require 'net/http'

module Uploadcare
  class MultipartUploadClient < UploadClient
    CHUNK_SIZE = 5 * 1024 * 1024 # 5MB chunks

    def start(filename, size, content_type = 'application/octet-stream', options = {})
      params = {
        filename: filename,
        size: size,
        content_type: content_type,
        UPLOADCARE_STORE: options[:store] || 'auto'
      }

      options[:metadata]&.each do |key, value|
        params["metadata[#{key}]"] = value
      end

      execute_request(:post, '/multipart/start/', params)
    end

    def upload_chunk(file_path, upload_data)
      File.open(file_path, 'rb') do |file|
        upload_data['parts'].each do |part|
          file.seek(part['start_offset'])
          chunk = file.read(part['end_offset'] - part['start_offset'])

          upload_part_to_s3(part['url'], chunk)
        end
      end
    end

    def complete(uuid)
      execute_request(:post, '/multipart/complete/', { uuid: uuid })
    end

    def upload_file(file_path, options = {})
      file_size = File.size(file_path)
      filename = options[:filename] || File.basename(file_path)

      # Start multipart upload
      upload_data = start(filename, file_size, 'application/octet-stream', options)

      # Upload chunks
      upload_chunk(file_path, upload_data)

      # Complete upload
      complete(upload_data['uuid'])
    end

    private

    def upload_part_to_s3(presigned_url, chunk)
      uri = URI(presigned_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Put.new(uri)
      request.body = chunk
      request['Content-Type'] = 'application/octet-stream'

      response = http.request(request)

      return if response.is_a?(Net::HTTPSuccess)

      raise Uploadcare::RequestError, "Failed to upload chunk: #{response.code}"
    end
  end
end

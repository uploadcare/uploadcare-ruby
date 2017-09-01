require_relative 'uploading_api/upload_params'

module Uploadcare
  module UploadingApi
    # intelegent guess for file or URL uploading
    def upload object, options = {}
      case object
      when File then upload_file(object, options)
      when Array then upload_files(object, options)
      # if object is a string, try to upload it as an URL
      when String then upload_url(object, options)
      else
        raise ArgumentError, "Expected `object` to be an Uploadcare::Api::File, "\
          "an Array or a valid URL string, received: `#{object}`"
      end
    end

    # Upload multiple files
    def upload_files(files, options = {})
      data = upload_params(options).for_file_upload(files)

      response = @upload_connection.post('/base/', data)

      response.body.values.map! { |f| Uploadcare::Api::File.new(self, f) }
    end

    # Upload single file
    def upload_file(file, options = {})
      upload_files([file], options).first
    end
    alias_method :create_file, :upload_file

    # Upload from an URL
    def upload_url(url, options = {})
      params = upload_params(options).for_url_upload(url)
      token = request_file_upload(params)

      upload_status = poll_upload_result(token)
      if upload_status['status'] == 'error'
        raise ArgumentError.new(upload_status['error'])
      end

      Uploadcare::Api::File.new(self, upload_status['file_id'])
    end
    alias_method :upload_from_url, :upload_url

    private

    def get_status_response(token)
      response = @upload_connection.post('/from_url/status/', {token: token})
      response.body
    end

    def request_file_upload(upload_params)
      response = @upload_connection.post('/from_url/', upload_params)
      token = response.body["token"]
    end

    def poll_upload_result(token)
      while true
        response = get_status_response(token)
        break(response) if ['success', 'error'].include?(response['status'])
        sleep 0.5
      end
    end

    def upload_params(request_options)
      UploadParams.new(@options, request_options)
    end
  end
end

# frozen_string_literal: true

module Uploadcare
  class UploaderClient < UploadClient
    def upload_file(file, options = {})
      File.open(file, 'rb') do |file_io|
        params = build_upload_params(options)
        params[:file] = Faraday::UploadIO.new(file_io, 'application/octet-stream')
        
        execute_request(:post, '/base/', params)
      end
    end

    def upload_files(files, options = {})
      results = files.map do |file|
        upload_file(file, options)
      end
      
      { files: results }
    end

    def upload_from_url(url, options = {})
      params = build_upload_params(options)
      params[:source_url] = url
      
      execute_request(:post, '/from_url/', params)
    end

    def check_upload_status(token)
      execute_request(:get, '/from_url/status/', { token: token })
    end

    def file_info(uuid)
      execute_request(:get, '/info/', { file_id: uuid })
    end

    private

    def build_upload_params(options)
      params = {}
      
      params[:store] = options[:store] if options.key?(:store)
      params[:filename] = options[:filename] if options[:filename]
      params[:check_URL_duplicates] = options[:check_duplicates] if options.key?(:check_duplicates)
      params[:save_URL_duplicates] = options[:save_duplicates] if options.key?(:save_duplicates)
      
      if options[:metadata]
        options[:metadata].each do |key, value|
          params["metadata[#{key}]"] = value
        end
      end
      
      params
    end
  end
end
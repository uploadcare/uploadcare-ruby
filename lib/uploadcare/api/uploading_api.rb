require "uri"
require 'mime/types'

module Uploadcare
  module UploadingApi
    # intelegent guess for file or url uploading
    def upload object
      # if object is file - uploading it as file
      if object.kind_of?(File)
        upload_file(object)

      # if a string - try to upload as url
      elsif object.kind_of?(String)
        upload_url(object)

      # TODO: uploading array of files
      elsif object.kind_of?(Array)
        upload_files(object)

      else
        raise ArgumentError.new "you should give File object, array of files or valid url string"
      end
    end


    def upload_files files
      if files.select {|f| !f.kind_of?(File)}.any?
        raise ArgumentError.new "one or more of given files is not actually files"
      else
        # response = upload_request :post, '/base/', {
        #   UPLOADCARE_PUB_KEY: @options[:public_key],
        #   files: files.map {|f| Faraday::UploadIO.new(f.path, extract_mime_type(f))}
        # }

        post = {
          UPLOADCARE_PUB_KEY: @options[:public_key],
        }

        files.each_with_index do |f, i|
          post["file[#{i}]"] = Faraday::UploadIO.new(f.path, extract_mime_type(f))
        end


        response = upload_request :post, '/base/', post

        uuids = upload_parse(response)

        files = uuids.values.map! {|f| Uploadcare::Api::File.new self, f }

      end
    end


    # upload file to servise
    def upload_file file
      if file.kind_of?(File)
        mime_type = extract_mime_type(file)
        
        response = upload_request :post, '/base/', {
          UPLOADCARE_PUB_KEY: @options[:public_key],
          file: Faraday::UploadIO.new(file.path, mime_type)
        }
        uuid = upload_parse(response)["file"]
        Uploadcare::Api::File.new self, uuid
      else
        raise ArgumentError.new 'expecting File object'
      end
    end


    #upload from url
    def upload_url url
      uri = URI.parse(url)
      
      if uri.kind_of?(URI::HTTP) # works both for HTTP and HTTPS as HTTPS inherits from HTTP
        token = get_token(url)

        while (response = get_status_response(token))['status'] == 'unknown'
          sleep 0.5
        end
        
        raise ArgumentError.new(response['error']) if response['status'] == 'error'
        uuid = response['file_id']
        Uploadcare::Api::File.new self, uuid
      else
        raise ArgumentError.new 'invalid url was given'
      end
    end
    alias_method :upload_from_url, :upload_url




    protected
      def upload_request method, path, params = {}
        connection = Uploadcare::Connections.upload_connection(@options)
        response = connection.send method, path, params
      end


      def upload_parse response
        raise ArgumentError.new(response.body) if response.status > 200
        begin
          JSON.parse(response.body)
        rescue JSON::ParserError
          response.body
        end
      end


    private
      def get_status_response token
        upload_parse(upload_request(:post, '/from_url/status/', {token: token}))
      end


      def get_token url
        response = upload_request :post, '/from_url/', { source_url: url, pub_key: @options[:public_key] }
        token = upload_parse(response)["token"]
      end

      def extract_mime_type file
        types = MIME::Types.of(file.path)
        types[0].content_type
      end
  end
end
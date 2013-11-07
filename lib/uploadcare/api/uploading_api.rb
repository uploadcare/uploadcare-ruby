require "uri"

module Uploadcare
  module UploadingApi
    # intelegent guess for file or url uploading
    def upload object
      # if object is file - uploading it as file
      if object.kind_of?(File)
        upload_file(object)

      # if a string - try to upload as url
      elsif object.kind_of?(String)
       # binding.pry
        upload_url(object)

      # TODO: uploading array of files
      # elsif object.kind_of?(Array)
        # some iteration and checking here, when mass upload
      else
        raise ArgumentError.new "you should give File object, array of files or valid url string"
      end
    end


    # upload file to servise
    def upload_file file
      if file.kind_of?(File)
        # response = upload_request :post, '/base/', {}
        Uploadcare::Api::File.new self, 'asdsadsa'
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


      def parse response
        raise ArgumentError.new(response.body) if response.status > 200
        begin
          JSON.parse(response.body)
        rescue JSON::ParserError
          response.body
        end
      end


    private
      def get_status_response token
        parse(upload_request(:post, '/from_url/status/', {token: token}))
      end


      def get_token url
        response = upload_request :post, '/from_url/', { source_url: url, pub_key: @options[:public_key] }
        token = parse(response)["token"]
      end
  end
end
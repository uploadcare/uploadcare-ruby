require "uri"

module Uploadcare
  module UploadingApi
    # intelegent guess for file or url uploading
    def upload object
      binding.pry
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
        Uploadcare::Api::File.new self, 'asdsadsa'
      else
        raise ArgumentError.new 'expecting File object'
      end
    end


    #upload from url
    def upload_url url
      uri = URI.parse(url)
      
      if uri.kind_of?(URI::HTTP) # works both for HTTP and HTTPS as HTTPS inherits from HTTP
        Uploadcare::Api::File.new self, 'asdsadsa'
      else
        raise ArgumentError.new 'invalid url was given'
      end
    end
  end
end
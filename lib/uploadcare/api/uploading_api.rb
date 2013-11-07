require "uri"

module Uploadcare
  module UploadingApi
    # intelegent guess for file or url uploading
    def upload object
      if object.kind_of?(File)
        file = object
        upload_file(file)
      elsif object.kind_of?(String)
        binding.
        url = object
      else
        raise ArgumentError.new "you should give File object or valid url string"
      end
    end

    # upload file to servise
    def upload_file file
      Uploadcare::File.new self, 'asdsadsa'
    end

    #upload from url
    def upload_url url
      Uploadcare::File.new self, 'asdsadsa'
    end
  end
end
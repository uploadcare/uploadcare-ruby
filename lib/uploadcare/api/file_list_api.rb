module Uploadcare
  module FileListApi
    # Available options:
    #
    #   limit -- a number of objects retrieved per request. Default: 100
    #   ordering -- sorting order of files in a list. Default: datetime_uploaded
    #   from -- a starting point for filtering files.
    #   stored -- true to include only stored files, false to exclude.
    #   removed -- true to include only removed files, false to exclude. Default: false
    #
    # Documentation: http://uploadcare.com/documentation/rest/#file-files
    def file_list options={}
      Validators::FileListOptionsValidator.new(options).validate

      data = get '/files/', options
      Uploadcare::Api::FileList.new self, data, options
    end
  end
end

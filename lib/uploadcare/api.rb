require 'json'
require 'ostruct'

require 'uploadcare/api/raw_api'
require 'uploadcare/api/connections'
require 'uploadcare/api/uploading_api'
require 'uploadcare/resources/file'
require 'uploadcare/resources/project'
require 'uploadcare/resources/file_list'
require 'uploadcare/api/file_api'
require 'uploadcare/api/project_api'
require 'uploadcare/api/file_list_api'


module Uploadcare
  class Api
    attr_reader :options
    
    include Uploadcare::RawApi
    include Uploadcare::UploadingApi
    include Uploadcare::FileApi
    include Uploadcare::ProjectApi
    include Uploadcare::FileListApi
  end
end
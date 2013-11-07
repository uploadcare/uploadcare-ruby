require 'json'
require 'ostruct'

require 'uploadcare/api/raw_api'
require 'uploadcare/api/connections'
require 'uploadcare/api/uploading_api'
require 'uploadcare/resources/file'
require 'uploadcare/api/file_api'


module Uploadcare
  class Api
    include Uploadcare::RawApi
    include Uploadcare::UploadingApi
    include Uploadcare::FileApi

    # def initiaize options={}
    #   super
    # end
  end
end
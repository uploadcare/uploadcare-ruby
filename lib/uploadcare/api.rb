require 'json'
require 'ostruct'

require 'uploadcare/raw_api'
require 'uploadcare/api/connections'
require 'uploadcare/api/uploading_api'
require 'uploadcare/api/file'


module Uploadcare
  class Api < Uploadcare::RawApi
    include Uploadcare::UploadingApi

    def initiaize options={}
      super
    end
  end
end
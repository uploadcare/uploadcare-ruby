require 'json'
require 'ostruct'
Dir[File.dirname(__FILE__) + '/rest/middlewares/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/rest/connections/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/api/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/resources/*.rb'].each {|file| require file }


module Uploadcare
  class Api
    attr_reader :options
    
    include Uploadcare::RawApi
    include Uploadcare::UploadingApi
    include Uploadcare::FileApi
    include Uploadcare::ProjectApi
    include Uploadcare::FileListApi
    include Uploadcare::GroupApi
    include Uploadcare::GroupListApi
  end
end
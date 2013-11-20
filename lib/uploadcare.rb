require 'faraday'
require 'json'
require 'ostruct'

require 'uploadcare/api'
require 'uploadcare/version'

module Uploadcare
  DEFAULT_SETTINGS = {
      public_key: 'demopublickey',
      private_key: 'demoprivatekey',
      upload_url_base: 'https://upload.uploadcare.com',
      api_url_base: 'https://api.uploadcare.com',
      static_url_base: 'http://www.ucarecdn.com',
      api_version: '0.3',
      cache_files: true,
    }

  USER_AGENT = "uploadcare-ruby/#{Uploadcare::VERSION}"
  

  def self.default_settings
    DEFAULT_SETTINGS
  end

  def self.user_agent
    USER_AGENT
  end

  UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
  
  GROUP_UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}~(?<count>\d+)$/
  
  CDN_URL_FILE_REGEX = /
     (?<uuid>[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})
     (?:\/-\/(?<operations>.*?))?\/?$
     /ix
  
  CDN_URL_GROUP_REGEX = /
     (?<uuid>[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}~(?<count>\d+))
     (?:\/-\/(?<operations>.*?))?\/?$
     /ix
end

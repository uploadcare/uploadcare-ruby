require 'faraday'
require 'json'
require 'ostruct'

require 'uploadcare/api'
require 'uploadcare/version'

module Uploadcare
  def self.default_settings
    {
      public_key: 'demopublickey',
      private_key: 'demoprivatekey',
      upload_url_base: 'https://upload.uploadcare.com',
      api_url_base: 'https://api.uploadcare.com',
      static_url_base: 'http://www.ucarecdn.com',
      api_version: '0.3',
      cache_files: true,
    }
  end

  def self.user_agent
    "uploadcare-api-ruby/#{Uploadcare::VERSION}"
  end

  UUID_REGEX = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
  CDN_URL_REGEX = /
     (?<uuid>[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})
     (?:\/-\/(?<operations>.*?))?\/?$
     /ix
end

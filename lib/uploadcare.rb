require 'faraday'
require 'json'
require 'ostruct'

require_relative 'uploadcare/api'
require_relative 'uploadcare/version'

module Uploadcare
  DEFAULT_SETTINGS = {
    public_key: 'demopublickey',
    private_key: 'demoprivatekey',
    upload_url_base: 'https://upload.uploadcare.com',
    api_url_base: 'https://api.uploadcare.com',
    static_url_base: 'https://ucarecdn.com',
    api_version: '0.5',
    cache_files: true,
    store_files_upon_uploading: false,
    auth_scheme: :secure
  }

  USER_AGENT = "uploadcare-ruby/#{Gem.ruby_version}/#{Uploadcare::VERSION}"

  def self.default_settings
    DEFAULT_SETTINGS
  end

  def self.user_agent(options={})
    return options[:user_agent].to_s if options[:user_agent]
    [USER_AGENT, options[:public_key]].join('/')
  end
end

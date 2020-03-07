# frozen_string_literal: true

require 'uploadcare_configuration'
require 'default_configuration'
require 'param/user_agent'

# File with api endpoints

ApiStruct::Settings.configure do |config|
  config.endpoints = {
    rest_api: {
      root: Uploadcare.configuration.rest_api_root,
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/vnd.uploadcare-v0.5+json',
        'User-Agent': Uploadcare::Param::UserAgent.call
      }
    },
    upload_api: {
      root: Uploadcare.configuration.upload_api_root,
      headers: {
        'User-Agent': Uploadcare::Param::UserAgent.call
      }
    },
    chunks_api: {
      root: ''
    }
  }
end

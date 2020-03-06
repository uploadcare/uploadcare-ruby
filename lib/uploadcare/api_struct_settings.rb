# frozen_string_literal: true

require 'uploadcare_configuration'
require 'default_configuration'

# File with api endpoints

ApiStruct::Settings.configure do |config|
  config.endpoints = {
    rest_api: {
      root: Uploadcare.configuration.rest_api_root,
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/vnd.uploadcare-v0.5+json'
      }
    },
    upload_api: {
      root: Uploadcare.configuration.upload_api_root
    },
    chunks_api: {
      root: ''
    }
  }
end

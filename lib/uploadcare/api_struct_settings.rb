# frozen_string_literal: true

require 'uploadcare_settings'

# File with api endpoints

ApiStruct::Settings.configure do |config|
  config.endpoints = {
    rest_api: {
      root: Uploadcare::REST_API_ROOT,
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/vnd.uploadcare-v0.5+json'
      }
    },
    upload_api: {
      root: Uploadcare::UPLOAD_API_ROOT
    },
    chunks_api: {
      root: ''
    }
  }
end

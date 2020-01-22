# frozen_string_literal: true

require 'uploadcare_settings'

# File with api endpoints

ApiStruct::Settings.configure do |config|
  config.endpoints = {
    rest_api: {
      root: 'https://api.uploadcare.com',
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/vnd.uploadcare-v0.5+json'
      }
    },
    upload_api: {
      root: 'https://upload.uploadcare.com'
    }
  }
end

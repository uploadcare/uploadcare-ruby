# frozen_string_literal: true

module Uploadcare
  PUBLIC_KEY = ENV.fetch('UPLOADCARE_PUBLIC_KEY')
  SECRET_KEY = ENV.fetch('UPLOADCARE_SECRET_KEY')
  AUTH_TYPE = 'Uploadcare.Simple'
  MAX_REQUEST_TRIES = 100
  BASE_REQUEST_SLEEP = 1 # seconds
  MAX_REQUEST_SLEEP = 60.0 # seconds
end

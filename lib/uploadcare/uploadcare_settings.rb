# frozen_string_literal: true

module Uploadcare
  PUBLIC_KEY = ENV.fetch('UPLOADCARE_PUBLIC_KEY')
  SECRET_KEY = ENV.fetch('UPLOADCARE_SECRET_KEY')
  AUTH_TYPE = 'Uploadcare.Simple'
  MULTIUPLOAD_SIZE_THRESHOLD = 100 * 1024 * 1024
end

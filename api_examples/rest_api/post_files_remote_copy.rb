# frozen_string_literal: true

# Copy a file to remote/custom storage
# NOTE: Custom storage must be configured in your Uploadcare Dashboard first:
#   Dashboard → Project Settings → Custom Storage
# See: https://uploadcare.com/docs/storage/custom-storage/

require_relative '../../lib/uploadcare'
require 'dotenv/load'
Uploadcare.configuration.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', 'YOUR_PUBLIC_KEY')
Uploadcare.configuration.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', 'YOUR_SECRET_KEY')

source_object = ENV.fetch('UPLOADCARE_FILE_UUID', '1bac376c-aa7e-4356-861b-dd2657b5bfd2')
target = ENV.fetch('UPLOADCARE_STORAGE_NAME', 'custom_storage_connected_to_the_project')
copied_file_url = Uploadcare::File.remote_copy(source: source_object, target: target, options: { make_public: true })
puts copied_file_url

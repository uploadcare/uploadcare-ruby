# frozen_string_literal: true

require_relative '../../lib/uploadcare'
require 'dotenv/load'

# Configure Uploadcare
Uploadcare.configure do |config|
  config.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY')
end

# Example: Complete a multipart upload
puts 'Example: Complete Multipart Upload'
puts '=' * 50

client = Uploadcare::UploadClient.new

# NOTE: You need a valid upload UUID from a previous multipart_start call
# This example shows the API call structure

upload_uuid = ENV.fetch('UPLOADCARE_MULTIPART_UUID', 'your-upload-uuid-here')

begin
  result = client.multipart_complete(uuid: upload_uuid)
  raise result.error if result.failure?

  response = result.success

  puts 'Multipart upload completed!'
  puts "File UUID: #{response['uuid']}"
  puts "Original filename: #{response['original_filename']}"
  puts "File size: #{response['size']} bytes"
  puts "MIME type: #{response['mime_type']}"
rescue StandardError => e
  puts "Error: #{e.message}"
  puts "\nNote: Replace 'your-upload-uuid-here' with a valid upload UUID"
  puts 'from a previous multipart_start call.'
end

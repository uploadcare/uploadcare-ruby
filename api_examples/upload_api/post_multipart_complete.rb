# frozen_string_literal: true

require_relative '../../lib/uploadcare'

# Load environment variables from .env file
env_file = File.expand_path('../../.env', __dir__)
if File.exist?(env_file)
  File.readlines(env_file).each do |line|
    next if line.start_with?('#') || line.strip.empty?

    key, value = line.strip.split('=', 2)
    ENV[key] = value if key && value
  end
end

# Configure Uploadcare
Uploadcare.configure do |config|
  config.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', nil)
end

# Example: Complete a multipart upload
puts 'Example: Complete Multipart Upload'
puts '=' * 50

client = Uploadcare::UploadClient.new

# NOTE: You need a valid upload UUID from a previous multipart_start call
# This example shows the API call structure

upload_uuid = 'your-upload-uuid-here'

begin
  response = client.multipart_complete(upload_uuid)

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

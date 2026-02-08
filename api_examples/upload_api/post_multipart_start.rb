# frozen_string_literal: true

require_relative '../../lib/uploadcare'
require 'dotenv/load'

# Configure Uploadcare
Uploadcare.configure do |config|
  config.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY')
end

# Example: Start a multipart upload
puts 'Example: Start Multipart Upload'
puts '=' * 50

client = Uploadcare::UploadClient.new

# File information
filename = 'large_video.mp4'
file_size = 150 * 1024 * 1024 # 150MB
content_type = 'video/mp4'

# Start multipart upload
response = client.multipart_start(filename: filename, size: file_size, content_type: content_type, store: true).success

puts 'Multipart upload started!'
puts "Upload UUID: #{response['uuid']}"

parts = response['parts']
if parts.nil? || !parts.is_a?(Array)
  puts 'Error: No parts array returned from multipart_start'
  exit 1
end

puts "Number of parts: #{parts.length}"
puts "\nPresigned URLs:"
parts.each_with_index do |url, index|
  puts "  Part #{index + 1}: #{url[0..60]}..."
end

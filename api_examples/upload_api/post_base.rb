#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../lib/uploadcare'

# Configure Uploadcare
Uploadcare.configure do |config|
  config.public_key = ENV['UPLOADCARE_PUBLIC_KEY'] || 'your_public_key'
  config.secret_key = ENV['UPLOADCARE_SECRET_KEY'] || 'your_secret_key'
end

# Upload a file using base upload
client = Uploadcare::UploadClient.new

puts 'Uploading file...'
result = nil
File.open('spec/fixtures/kitten.jpeg', 'rb') do |file|
  result = client.upload_file(file: file, store: true)
end

if result.failure?
  warn "Upload failed: #{result.error_message}"
  exit 1
end

payload = result.success
file_name, file_uuid = payload.first

puts 'File uploaded successfully!'
puts "UUID: #{file_uuid}"
puts "Original filename: #{file_name}"

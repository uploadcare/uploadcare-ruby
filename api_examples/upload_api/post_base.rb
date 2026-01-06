#!/usr/bin/env ruby
# frozen_string_literal: true

require 'uploadcare'

# Configure Uploadcare
Uploadcare.configure do |config|
  config.public_key = ENV['UPLOADCARE_PUBLIC_KEY'] || 'your_public_key'
  config.secret_key = ENV['UPLOADCARE_SECRET_KEY'] || 'your_secret_key'
end

# Upload a file using base upload
file = File.open('spec/fixtures/kitten.jpeg', 'rb')
client = Uploadcare::UploadClient.new

puts 'Uploading file...'
result = client.upload_file(file, store: true)

puts 'File uploaded successfully!'
puts "UUID: #{result['file']}"
puts "Original filename: #{result['original_filename']}"

file.close

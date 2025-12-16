#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple Upload Example
# Demonstrates the basic file upload functionality

require_relative '../lib/uploadcare'
# Load environment variables from .env file if dotenv is available
begin
  require 'dotenv/load'
rescue LoadError
  # dotenv not available, skip loading .env file
end

# Configure Uploadcare
Uploadcare.configure do |config|
  config.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', nil)
  config.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', nil)
end

# Get file path from command line argument
file_path = ARGV[0]

unless file_path && File.exist?(file_path)
  puts 'Usage: ruby simple_upload.rb <file_path>'
  puts 'Example: ruby simple_upload.rb photo.jpg'
  exit 1
end

puts "Uploading: #{file_path}"
puts "Size: #{(File.size(file_path) / 1024.0).round(2)} KB"
puts

begin
  # Open and upload the file
  file = File.open(file_path, 'rb')
  result = Uploadcare::Uploader.upload(file, store: true)
  file.close

  # Display results
  puts '✓ Upload successful!'
  puts
  puts "UUID: #{result.uuid}"
  puts "Filename: #{result.original_filename}"
  puts "CDN URL: https://ucarecdn.com/#{result.uuid}/"
  puts
  puts 'The file has been stored and is ready to use.'
rescue StandardError => e
  puts "✗ Upload failed: #{e.message}"
  exit 1
end

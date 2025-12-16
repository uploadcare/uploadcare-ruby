#!/usr/bin/env ruby
# frozen_string_literal: true

# URL Upload Example
# Demonstrates uploading files from remote URLs

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

# Get URL from command line argument
url = ARGV[0]

unless url&.match?(%r{^https?://})
  puts 'Usage: ruby url_upload.rb <url>'
  puts 'Example: ruby url_upload.rb https://example.com/image.jpg'
  exit 1
end

puts 'URL Upload'
puts '=' * 50
puts "URL: #{url}"
puts

begin
  # Upload from URL (sync mode with polling)
  puts 'Starting upload...'
  result = Uploadcare::Uploader.upload(url, store: true)

  puts '✓ Upload successful!'
  puts
  puts "UUID: #{result.uuid}"
  puts "Filename: #{result.original_filename}"
  puts "Size: #{(result.size / 1024.0).round(2)} KB"
  puts "MIME type: #{result.mime_type}"
  puts
  puts "CDN URL: https://ucarecdn.com/#{result.uuid}/"
  puts
  puts 'Advanced Usage:'
  puts
  puts '# Async mode (returns immediately with token):'
  puts 'upload_client = Uploadcare::UploadClient.new'
  puts "response = upload_client.upload_from_url('#{url}', async: true)"
  puts "token = response['token']"
  puts
  puts '# Check status later:'
  puts 'status = upload_client.upload_from_url_status(token)'
  puts "puts status['status']  # 'waiting', 'progress', 'success', or 'error'"
rescue StandardError => e
  puts "✗ Upload failed: #{e.message}"
  puts
  puts 'Common issues:'
  puts '- URL must be publicly accessible'
  puts '- URL must return a valid file'
  puts '- Some file types may not be supported'
  exit 1
end

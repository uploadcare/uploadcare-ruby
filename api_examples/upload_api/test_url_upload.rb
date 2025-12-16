#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../lib/uploadcare'
require 'dotenv/load'

# Configure Uploadcare
Uploadcare.configure do |config|
  config.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', nil)
  config.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', nil)
end

puts 'Testing URL upload with real URL...'
puts

# Test with a real, publicly accessible image
url = 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400'

puts "URL: #{url}"
puts 'Uploading...'

begin
  result = Uploadcare::Uploader.upload(url, store: true)

  puts '✓ Success!'
  puts "UUID: #{result.uuid}"
  puts "Filename: #{result.original_filename}"
  puts "Size: #{result.size}" if result.respond_to?(:size)
rescue StandardError => e
  puts "✗ Error: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end

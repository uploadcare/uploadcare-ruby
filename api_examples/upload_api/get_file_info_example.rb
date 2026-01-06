#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../lib/uploadcare'
require 'dotenv/load'

# Configure Uploadcare
Uploadcare.configure do |config|
  config.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', nil)
  config.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', nil)
end

# You need a file UUID to get info
# Replace this with an actual file UUID from your account
file_id = ARGV[0] || 'your-file-uuid'

puts "Getting file information for: #{file_id}"
puts

upload_client = Uploadcare::UploadClient.new

begin
  info = upload_client.file_info(file_id)

  puts 'File Information:'
  puts "  UUID: #{info['uuid']}"
  puts "  Filename: #{info['original_filename']}"
  puts "  Size: #{info['size']} bytes (#{(info['size'] / 1024.0).round(2)} KB)"
  puts "  MIME type: #{info['mime_type']}"
  puts "  Is image: #{info['is_image']}"
  puts "  Is ready: #{info['is_ready']}"
  puts "  Uploaded at: #{info['datetime_uploaded']}"
  puts

  if info['image_info']
    puts 'Image Information:'
    puts "  Width: #{info['image_info']['width']}px"
    puts "  Height: #{info['image_info']['height']}px"
    puts "  Format: #{info['image_info']['format']}"
    puts "  Color mode: #{info['image_info']['color_mode']}"
  end

  if info['content_info']
    puts
    puts 'Content Information:'
    puts "  MIME: #{info['content_info']['mime']['mime']}"
    puts "  Type: #{info['content_info']['mime']['type']}"
    puts "  Subtype: #{info['content_info']['mime']['subtype']}"
  end
rescue StandardError => e
  puts "Error: #{e.message}"
  puts
  puts 'Usage: ruby get_file_info_example.rb <file-uuid>'
  puts 'Example: ruby get_file_info_example.rb abc123-def456-7890'
end

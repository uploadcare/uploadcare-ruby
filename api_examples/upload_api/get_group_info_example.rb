#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../lib/uploadcare'
require 'dotenv/load'

# Configure Uploadcare
Uploadcare.configure do |config|
  config.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY')
  config.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY')
end

# You need a group ID to get info
# Replace this with an actual group ID from your account
group_id = ARGV[0] || 'your-group-uuid~2'

puts "Getting group information for: #{group_id}"
puts

upload_client = Uploadcare::UploadClient.new

begin
  result = upload_client.group_info(group_id: group_id)
  raise result.error if result.failure?

  info = result.success

  puts 'Group Information:'
  puts "  ID: #{info['id']}"
  puts "  Files count: #{info['files_count']}"
  puts "  CDN URL: #{info['cdn_url']}"
  puts "  Created at: #{info['datetime_created']}"
  puts "  Stored at: #{info['datetime_stored'] || 'Not stored'}"
  puts

  if info['files']
    puts 'Files in group:'
    info['files'].each_with_index do |file, index|
      puts "  #{index + 1}. UUID: #{file['uuid']}"
      puts "     Size: #{file['size']} bytes" if file['size']
      puts "     Filename: #{file['original_filename']}" if file['original_filename']
    end
  end
rescue StandardError => e
  puts "Error: #{e.message}"
  puts
  puts 'Usage: ruby get_group_info_example.rb <group-uuid>'
  puts 'Example: ruby get_group_info_example.rb abc123-def456~3'
end

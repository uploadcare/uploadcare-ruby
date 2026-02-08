#!/usr/bin/env ruby
# frozen_string_literal: true

# Group Creation Example
# Demonstrates creating file groups from uploaded files

require_relative '../lib/uploadcare'
require 'dotenv/load'

# Configure Uploadcare
Uploadcare.configure do |config|
  config.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY')
  config.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY')
end

# Get file paths from command line arguments
file_paths = ARGV

if file_paths.empty?
  puts 'Usage: ruby group_creation.rb <file1> <file2> <file3> ...'
  puts 'Example: ruby group_creation.rb photo1.jpg photo2.jpg photo3.jpg'
  exit 1
end

# Validate files exist
file_paths.each do |path|
  unless File.exist?(path)
    puts "Error: File not found: #{path}"
    exit 1
  end
end

puts "Group Creation - #{file_paths.length} files"
puts '=' * 50
puts

begin
  # Step 1: Upload all files
  puts 'Step 1: Uploading files...'
  upload_client = Uploadcare::UploadClient.new
  uuids = []

  file_paths.each_with_index do |path, index|
    File.open(path, 'rb') do |file|
      response = upload_client.upload_file(file: file, store: true)
      uuid = response.values.first
      uuids << uuid
      puts "  #{index + 1}. #{File.basename(path)} → #{uuid}"
    end
  end

  puts
  puts "✓ Uploaded #{uuids.length} files"
  puts

  # Step 2: Create group
  puts 'Step 2: Creating group...'
  group = Uploadcare::Group.create(uuids: uuids)

  puts '✓ Group created!'
  puts
  puts 'Group Details:'
  puts '-' * 50
  puts "Group ID: #{group.id}"
  puts "Files count: #{group.files_count}"
  puts "CDN URL: #{group.cdn_url}"
  puts "Created at: #{group.datetime_created}"
  puts

  # Step 3: Get group info
  puts 'Step 3: Retrieving group info...'
  info = upload_client.group_info(group_id: group.id)

  puts '✓ Group info retrieved'
  puts
  puts 'Files in group:'
  puts '-' * 50

  info['files'].each_with_index do |file, index|
    puts "#{index + 1}. #{file['original_filename']}"
    puts "   UUID: #{file['uuid']}"
    puts "   Size: #{(file['size'] / 1024.0).round(2)} KB"
    puts "   URL: https://ucarecdn.com/#{file['uuid']}/"
    puts
  end

  puts 'Group URL:'
  puts group.cdn_url
  puts
  puts 'You can access individual files in the group:'
  puts "#{group.cdn_url}nth/0/  # First file"
  puts "#{group.cdn_url}nth/1/  # Second file"
rescue StandardError => e
  puts "✗ Group creation failed: #{e.message}"
  exit 1
end

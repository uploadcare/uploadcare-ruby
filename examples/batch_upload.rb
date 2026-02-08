#!/usr/bin/env ruby
# frozen_string_literal: true

# Batch Upload Example
# Demonstrates uploading multiple files at once

require_relative '../lib/uploadcare'
require 'dotenv/load'

# Configure Uploadcare
Uploadcare.configure do |config|
  config.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', nil)
  config.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', nil)
end

# Get file paths from command line arguments
file_paths = ARGV

if file_paths.empty?
  puts 'Usage: ruby batch_upload.rb <file1> <file2> <file3> ...'
  puts 'Example: ruby batch_upload.rb photo1.jpg photo2.jpg photo3.jpg'
  exit 1
end

# Validate files exist
file_paths.each do |path|
  unless File.exist?(path)
    puts "Error: File not found: #{path}"
    exit 1
  end
end

puts "Batch Upload - #{file_paths.length} files"
puts '=' * 50
puts

# Open all files
files = file_paths.map { |path| File.open(path, 'rb') }

begin
  # Upload all files
  results = Uploadcare::Uploader.upload(object: files, store: true)

  # Close files
  files.each(&:close)

  # Display results
  puts '✓ Batch upload complete!'
  puts
  puts 'Results:'
  puts '-' * 50

  results.each_with_index do |file, index|
    puts "#{index + 1}. #{file.original_filename}"
    puts "   UUID: #{file.uuid}"
    puts "   CDN URL: https://ucarecdn.com/#{file.uuid}/"
    puts
  end

  puts "Successfully uploaded #{results.length} files"
rescue StandardError => e
  files.each(&:close)
  puts "✗ Batch upload failed: #{e.message}"
  exit 1
end

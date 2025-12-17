#!/usr/bin/env ruby
# frozen_string_literal: true

# Large File Upload Example
# Demonstrates multipart upload with parallel processing

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

# Validate required configuration
unless Uploadcare.configuration.public_key
  puts 'Error: UPLOADCARE_PUBLIC_KEY environment variable is required'
  puts 'Please set UPLOADCARE_PUBLIC_KEY=your_public_key in your environment or .env file'
  exit 1
end

# Get file path and optional thread count
file_path = ARGV[0]
threads = (ARGV[1] || 4).to_i

unless file_path && File.exist?(file_path)
  puts 'Usage: ruby large_file_upload.rb <file_path> [threads]'
  puts 'Example: ruby large_file_upload.rb large_video.mp4 4'
  puts
  puts 'threads: Number of parallel upload threads (default: 4)'
  exit 1
end

file_size = File.size(file_path)
file_size_mb = (file_size / 1024.0 / 1024.0).round(2)

if file_size < 10_000_000
  puts 'Warning: File is < 10MB. Multipart upload is recommended for files >= 10MB'
  puts 'The upload will still work but may use base upload instead.'
  puts
end

puts 'Large File Upload'
puts '=' * 50
puts "File: #{file_path}"
puts "Size: #{file_size_mb} MB"
puts "Threads: #{threads}"
puts

begin
  upload_client = Uploadcare::UploadClient.new
  start_time = Time.now

  # Upload with multipart and parallel threads
  result = File.open(file_path, 'rb') do |file|
    upload_client.multipart_upload(file,
                                   store: true,
                                   threads: threads,
                                   metadata: {
                                     source: 'large_file_example',
                                     upload_method: 'multipart'
                                   }) do |progress|
      uploaded_mb = (progress[:uploaded] / 1024.0 / 1024.0).round(2)
      total_mb = (progress[:total] / 1024.0 / 1024.0).round(2)
      percentage = progress[:percentage].to_i
      part = progress[:part]
      total_parts = progress[:total_parts]

      # Progress bar
      bar_length = 30
      filled = (bar_length * percentage / 100).to_i
      bar = ('█' * filled) + ('░' * (bar_length - filled))

      print "\r#{bar} #{percentage}% | Part #{part}/#{total_parts} | #{uploaded_mb}/#{total_mb} MB"
      $stdout.flush
    end
  end
  elapsed = Time.now - start_time

  puts
  puts
  puts '✓ Upload successful!'
  puts
  puts 'Upload Details:'
  puts '-' * 50
  puts "UUID: #{result['uuid']}"
  puts "Size: #{file_size_mb} MB"
  puts "Time: #{elapsed.round(2)} seconds"
  puts "Speed: #{(file_size_mb / elapsed).round(2)} MB/s"
  puts "Threads: #{threads}"
  puts 'Method: Multipart upload'
  puts
  puts "CDN URL: https://ucarecdn.com/#{result['uuid']}/"
  puts
  puts 'Performance Tips:'
  puts '- Use 4-8 threads for optimal performance'
  puts '- More threads = faster upload (up to network limits)'
  puts '- Adjust chunk size for very large files'
rescue StandardError => e
  puts
  puts "✗ Upload failed: #{e.message}"
  exit 1
end

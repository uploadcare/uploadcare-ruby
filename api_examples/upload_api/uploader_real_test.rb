#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../lib/uploadcare'
require 'dotenv/load'

# Configure Uploadcare
Uploadcare.configure do |config|
  config.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', nil)
  config.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', nil)
end

puts '=' * 80
puts 'Uploadcare Uploader - Real Data Test'
puts '=' * 80
puts

# Test 1: Upload small file
puts '1. Testing small file upload (< 10MB)...'
begin
  file = File.open('spec/fixtures/kitten.jpeg', 'rb')
  result = Uploadcare::Uploader.upload(file, store: true)
  file.close

  puts '   ✓ Success!'
  puts "   UUID: #{result.uuid}"
  puts "   Filename: #{result.original_filename}"
  puts "   Type: #{result.class}"
rescue StandardError => e
  puts "   ✗ Error: #{e.message}"
  puts "   #{e.backtrace.first(3).join("\n   ")}"
end
puts

# Test 2: Upload from URL
puts '2. Testing URL upload...'
begin
  url = 'https://ucarecdn.com/a7d1b5c6-b6e5-4f6a-9c7d-8e9f0a1b2c3d/example.jpg'
  result = Uploadcare::Uploader.upload(url, store: true)

  puts '   ✓ Success!'
  puts "   UUID: #{result.uuid}"
  puts "   Type: #{result.class}"
rescue StandardError => e
  puts "   ✗ Error: #{e.message}"
  puts "   #{e.backtrace.first(3).join("\n   ")}"
end
puts

# Test 3: Upload large file with multipart
puts '3. Testing large file upload (>= 10MB) with multipart...'
begin
  file_path = 'spec/fixtures/big.jpeg'

  if File.exist?(file_path) && File.size(file_path) >= 10_000_000
    file = File.open(file_path, 'rb')
    file_size_mb = (file.size / 1024.0 / 1024.0).round(2)
    puts "   File size: #{file_size_mb} MB"

    result = Uploadcare::Uploader.upload(file, store: true) do |progress|
      if progress.is_a?(Hash)
        percentage = progress[:percentage] || 0
        part = progress[:part] || 0
        total_parts = progress[:total_parts] || 0
        print "\r   Progress: #{percentage}% - Part #{part}/#{total_parts}"
      end
    end
    file.close

    puts
    puts '   ✓ Success!'
    puts "   UUID: #{result.uuid}"
    puts "   Type: #{result.class}"
  else
    puts '   ⚠ Skipped: big.jpeg not found or too small'
    puts '   Create with: dd if=/dev/zero of=spec/fixtures/big.jpeg bs=1M count=10'
  end
rescue StandardError => e
  puts
  puts "   ✗ Error: #{e.message}"
  puts "   #{e.backtrace.first(5).join("\n   ")}"
end
puts

# Test 4: Upload multiple files
puts '4. Testing batch upload...'
begin
  files = [
    File.open('spec/fixtures/kitten.jpeg', 'rb'),
    File.open('spec/fixtures/another_kitten.jpeg', 'rb')
  ]

  results = Uploadcare::Uploader.upload(files, store: true)

  files.each(&:close)

  puts '   ✓ Success!'
  puts "   Uploaded #{results.length} files"
  results.each_with_index do |uploaded_file, i|
    puts "   File #{i + 1}: #{uploaded_file.uuid} (#{uploaded_file.original_filename})"
  end
rescue StandardError => e
  puts "   ✗ Error: #{e.message}"
  puts "   #{e.backtrace.first(3).join("\n   ")}"
end
puts

puts '=' * 80
puts 'Test Complete!'
puts '=' * 80

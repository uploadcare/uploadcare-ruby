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
puts 'Uploadcare Uploader Module Demo'
puts '=' * 80
puts

# Example 1: Upload a small file (auto-detects base upload)
puts '1. Uploading small file (auto-detects base upload)...'
begin
  response = Uploadcare::Uploader.upload('spec/fixtures/kitten.jpeg', store: true)
  puts "   ✓ Success! UUID: #{response['kitten.jpeg']}"
  puts '   Method used: Base upload (file < 10MB)'
rescue StandardError => e
  puts "   ✗ Error: #{e.message}"
end
puts

# Example 2: Upload from URL
puts '2. Uploading from URL (auto-detects URL upload)...'
begin
  response = Uploadcare::Uploader.upload(
    'https://ucarecdn.com/a7d1b5c6-b6e5-4f6a-9c7d-8e9f0a1b2c3d/example.jpg',
    store: true
  )
  puts "   ✓ Success! UUID: #{response['uuid']}"
  puts '   Method used: URL upload'
rescue StandardError => e
  puts "   ✗ Error: #{e.message}"
end
puts

# Example 3: Upload large file with progress (auto-detects multipart)
puts '3. Uploading large file with progress (auto-detects multipart)...'
begin
  # Use the big.jpeg fixture (should be >= 10MB for multipart)
  file_path = 'spec/fixtures/big.jpeg'

  if File.exist?(file_path) && File.size(file_path) >= 10_000_000
    puts "   File size: #{(File.size(file_path) / 1024.0 / 1024.0).round(2)} MB"

    response = Uploadcare::Uploader.upload(file_path, store: true) do |progress|
      percentage = progress[:percentage]
      uploaded_mb = (progress[:uploaded] / 1024.0 / 1024.0).round(2)
      total_mb = (progress[:total] / 1024.0 / 1024.0).round(2)
      part = progress[:part]
      total_parts = progress[:total_parts]

      print "\r   Progress: #{percentage}% (#{uploaded_mb}/#{total_mb} MB) - Part #{part}/#{total_parts}"
    end

    puts
    puts "   ✓ Success! UUID: #{response['uuid']}"
    puts '   Method used: Multipart upload (file >= 10MB)'
  else
    puts '   ⚠ Skipped: big.jpeg not found or too small (need >= 10MB)'
    puts '   To test multipart upload, create a file >= 10MB:'
    puts '   dd if=/dev/zero of=spec/fixtures/big.jpeg bs=1M count=10'
  end
rescue StandardError => e
  puts
  puts "   ✗ Error: #{e.message}"
end
puts

# Example 4: Upload with File object
puts '4. Uploading with File object...'
begin
  file = File.open('spec/fixtures/kitten.jpeg', 'rb')
  response = Uploadcare::Uploader.upload(file, store: true, metadata: { source: 'demo_script' })
  file.close

  puts "   ✓ Success! UUID: #{response['kitten.jpeg']}"
  puts '   Method used: Auto-detected from File object'
rescue StandardError => e
  puts "   ✗ Error: #{e.message}"
end
puts

# Example 5: Batch upload multiple files
puts '5. Batch uploading multiple files...'
begin
  files = [
    'spec/fixtures/kitten.jpeg',
    'spec/fixtures/another_kitten.jpeg'
  ]

  # Filter to only existing files
  existing_files = files.select { |f| File.exist?(f) }

  if existing_files.any?
    puts "   Uploading #{existing_files.length} files..."

    results = Uploadcare::Uploader.upload_files(existing_files, store: true) do |result|
      if result[:success]
        puts "   ✓ #{File.basename(result[:source])}: Success"
      else
        puts "   ✗ #{File.basename(result[:source])}: #{result[:error]}"
      end
    end

    successful = results.count { |r| r[:success] }
    puts "   Summary: #{successful}/#{results.length} files uploaded successfully"
  else
    puts '   ⚠ No files found to upload'
  end
rescue StandardError => e
  puts "   ✗ Error: #{e.message}"
end
puts

# Example 6: Batch upload with parallel processing
puts '6. Batch uploading with parallel processing (2 threads)...'
begin
  files = [
    'spec/fixtures/kitten.jpeg',
    'spec/fixtures/another_kitten.jpeg'
  ]

  existing_files = files.select { |f| File.exist?(f) }

  if existing_files.any?
    puts "   Uploading #{existing_files.length} files in parallel..."

    results = Uploadcare::Uploader.upload_files(existing_files, store: true, parallel: 2)

    successful = results.count { |r| r[:success] }
    puts "   ✓ Completed: #{successful}/#{results.length} files uploaded successfully"
  else
    puts '   ⚠ No files found to upload'
  end
rescue StandardError => e
  puts "   ✗ Error: #{e.message}"
end
puts

puts '=' * 80
puts 'Demo Complete!'
puts '=' * 80

#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../lib/uploadcare'
require 'dotenv/load'

# Configure Uploadcare
Uploadcare.configure do |config|
  config.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY')
  config.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY')
end

puts '=' * 80
puts 'Uploadcare Uploader Module Demo'
puts '=' * 80
puts

# Example 1: Upload a small file (auto-detects base upload)
puts '1. Uploading small file (auto-detects base upload)...'
begin
  response = nil
  File.open('spec/fixtures/kitten.jpeg', 'rb') do |file|
    response = Uploadcare::Uploader.upload(object: file, store: true)
  end
  puts "   ✓ Success! UUID: #{response.uuid}"
  puts "   Filename: #{response.original_filename}"
  puts '   Method used: Base upload (file < 10MB)'
rescue StandardError => e
  puts "   ✗ Error: #{e.message}"
end
puts

# Example 2: Upload from URL
puts '2. Uploading from URL (auto-detects URL upload)...'
begin
  response = Uploadcare::Uploader.upload(
    object: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=200',
    store: true
  )
  puts "   ✓ Success! UUID: #{response.uuid}"
  puts "   Filename: #{response.original_filename}"
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

    response = nil
    File.open(file_path, 'rb') do |file|
      response = Uploadcare::Uploader.upload(object: file, store: true) do |progress|
        percentage = progress[:percentage]
        uploaded_mb = (progress[:uploaded] / 1024.0 / 1024.0).round(2)
        total_mb = (progress[:total] / 1024.0 / 1024.0).round(2)
        part = progress[:part]
        total_parts = progress[:total_parts]

        print "\r   Progress: #{percentage}% (#{uploaded_mb}/#{total_mb} MB) - Part #{part}/#{total_parts}"
      end
    end

    puts
    puts "   ✓ Success! UUID: #{response.uuid}"
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
  File.open('spec/fixtures/kitten.jpeg', 'rb') do |file|
    response = Uploadcare::Uploader.upload(object: file, store: true, metadata: { source: 'demo_script' })
    puts "   ✓ Success! UUID: #{response.uuid}"
    puts "   Filename: #{response.original_filename}"
    puts '   Method used: Auto-detected from File object'
  end
rescue StandardError => e
  puts "   ✗ Error: #{e.message}"
end
puts

# Example 5: Batch upload multiple files
puts '5. Batch uploading multiple files...'
files = []
begin
  file_paths = [
    'spec/fixtures/kitten.jpeg',
    'spec/fixtures/another_kitten.jpeg'
  ]

  # Filter to only existing files and open them
  files = file_paths.select { |f| File.exist?(f) }.map { |f| File.open(f, 'rb') }

  if files.any?
    puts "   Uploading #{files.length} files..."

    results = Uploadcare::Uploader.upload(object: files, store: true)

    puts "   ✓ Batch upload successful (#{results.length} files)"
    results.each_with_index do |uploaded_file, i|
      puts "   File #{i + 1}: #{uploaded_file.uuid} (#{uploaded_file.original_filename})"
    end
  else
    puts '   ⚠ No files found to upload'
  end
rescue StandardError => e
  puts "   ✗ Error: #{e.message}"
ensure
  files.each(&:close)
end
puts

puts '=' * 80
puts 'Demo Complete!'
puts '=' * 80

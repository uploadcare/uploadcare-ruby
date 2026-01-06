#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../lib/uploadcare'
require 'dotenv/load'

# Configure Uploadcare
Uploadcare.configure do |config|
  config.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', nil)
  config.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', nil)
end

def print_header(title)
  puts
  puts '=' * 80
  puts title
  puts '=' * 80
  puts
end

def print_success(message, details = {})
  puts "✓ #{message}"
  details.each { |key, value| puts "  #{key}: #{value}" }
end

def print_error(message, error)
  puts "✗ #{message}"
  puts "  Error: #{error.message}"
end

print_header('Uploadcare Upload API - Comprehensive Demo')

# Test 1: Small file upload (auto-detects base upload)
puts '1. Small File Upload (< 10MB)'
puts '   Method: Base upload (POST /base/)'
puts
begin
  file = File.open('spec/fixtures/kitten.jpeg', 'rb')
  file_size = (file.size / 1024.0).round(2)

  result = Uploadcare::Uploader.upload(file, store: true)
  file.close

  print_success('Upload successful', {
                  'UUID' => result.uuid,
                  'Filename' => result.original_filename,
                  'Size' => "#{file_size} KB",
                  'Method' => 'Base upload (auto-detected)'
                })
rescue StandardError => e
  print_error('Upload failed', e)
end

# Test 2: URL upload
puts
puts '2. URL Upload'
puts '   Method: Upload from URL (POST /from_url/)'
puts
begin
  url = 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400'

  result = Uploadcare::Uploader.upload(url, store: true)

  print_success('Upload successful', {
                  'UUID' => result.uuid,
                  'Filename' => result.original_filename,
                  'Size' => "#{(result.size / 1024.0).round(2)} KB",
                  'Method' => 'URL upload (auto-detected)'
                })
rescue StandardError => e
  print_error('Upload failed', e)
end

# Test 3: Large file with multipart upload
puts
puts '3. Large File Upload (>= 10MB)'
puts '   Method: Multipart upload (POST /multipart/start/, PUT parts, POST /multipart/complete/)'
puts
begin
  file_path = 'spec/fixtures/big.jpeg'

  if File.exist?(file_path) && File.size(file_path) >= 10_000_000
    file = File.open(file_path, 'rb')
    file_size_mb = (file.size / 1024.0 / 1024.0).round(2)

    puts "   File size: #{file_size_mb} MB"
    puts '   Uploading with progress tracking...'
    puts

    last_percentage = 0
    result = Uploadcare::Uploader.upload(file, store: true) do |progress|
      if progress.is_a?(Hash) && progress[:percentage]
        percentage = progress[:percentage].to_i
        if percentage > last_percentage
          print "   Progress: #{'█' * (percentage / 5)}#{'░' * (20 - (percentage / 5))} #{percentage}%\r"
          last_percentage = percentage
        end
      end
    end
    file.close

    puts
    puts
    print_success('Upload successful', {
                    'UUID' => result.uuid,
                    'Size' => "#{file_size_mb} MB",
                    'Method' => 'Multipart upload (auto-detected)'
                  })
  else
    puts '   ⚠ Skipped: big.jpeg not found or too small (need >= 10MB)'
    puts '   Create test file with:'
    puts '   dd if=/dev/zero of=spec/fixtures/big.jpeg bs=1M count=10'
  end
rescue StandardError => e
  puts
  print_error('Upload failed', e)
end

# Test 4: Batch upload
puts
puts '4. Batch Upload (Multiple Files)'
puts '   Method: Multiple base uploads'
puts
begin
  files = [
    File.open('spec/fixtures/kitten.jpeg', 'rb'),
    File.open('spec/fixtures/another_kitten.jpeg', 'rb')
  ]

  puts "   Uploading #{files.length} files..."

  results = Uploadcare::Uploader.upload(files, store: true)

  files.each(&:close)

  print_success("Batch upload successful (#{results.length} files)")
  results.each_with_index do |file, i|
    puts "  File #{i + 1}: #{file.uuid} (#{file.original_filename})"
  end
rescue StandardError => e
  print_error('Batch upload failed', e)
end

# Test 5: Upload with metadata
puts
puts '5. Upload with Metadata'
puts '   Method: Base upload with custom metadata'
puts
begin
  file = File.open('spec/fixtures/kitten.jpeg', 'rb')

  result = Uploadcare::Uploader.upload(file,
                                       store: true,
                                       metadata: {
                                         source: 'demo_script',
                                         category: 'test',
                                         timestamp: Time.now.to_i.to_s
                                       })
  file.close

  print_success('Upload with metadata successful', {
                  'UUID' => result.uuid,
                  'Filename' => result.original_filename,
                  'Metadata' => 'Custom metadata attached'
                })
rescue StandardError => e
  print_error('Upload failed', e)
end

print_header('Demo Complete!')

puts 'Summary:'
puts '  ✓ Base upload (small files < 10MB)'
puts '  ✓ URL upload (from remote URLs)'
puts '  ✓ Multipart upload (large files >= 10MB with progress)'
puts '  ✓ Batch upload (multiple files)'
puts '  ✓ Metadata support'
puts
puts 'All upload methods use smart auto-detection based on:'
puts '  - Source type (URL, File, Array)'
puts '  - File size (< 10MB = base, >= 10MB = multipart)'
puts

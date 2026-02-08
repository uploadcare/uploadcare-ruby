# frozen_string_literal: true

require 'fileutils'
require_relative '../../lib/uploadcare'
require 'dotenv/load'

# Configure Uploadcare
Uploadcare.configure do |config|
  config.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY')
end

# Example: Complete multipart upload with high-level API
puts 'Example: High-Level Multipart Upload'
puts '=' * 50

client = Uploadcare::UploadClient.new

# Create a test file (11MB - minimum for multipart)
test_file_path = 'test_multipart_file.txt'
puts "\nCreating test file (11MB)..."
File.open(test_file_path, 'wb') do |f|
  # Write text data instead of binary to avoid file type restrictions
  (11 * 1024).times { f.write('This is test data for multipart upload. ' * 25) }
end

begin
  file = File.open(test_file_path, 'rb')
  file_size = file.size

  puts "File created: #{test_file_path} (#{file_size} bytes)"
  puts "\nUploading with progress tracking..."
  puts '=' * 50

  # Upload with progress tracking
  response = client.multipart_upload(file: file, store: true) do |progress|
    percentage = (progress[:uploaded].to_f / progress[:total] * 100).round(2)
    uploaded = progress[:uploaded]
    total = progress[:total]
    puts "Part #{progress[:part]}/#{progress[:total_parts]}: #{percentage}% (#{uploaded}/#{total} bytes)"
  end
  response = response.success

  puts "\n#{'=' * 50}"
  puts 'Upload complete!'
  puts "File UUID: #{response['uuid']}"
  puts "File URL: https://ucarecdn.com/#{response['uuid']}/"

  # Example with parallel uploads
  puts "\n#{'=' * 50}"
  puts 'Example: Parallel Upload (4 threads)'
  puts '=' * 50

  file.rewind
  response2 = client.multipart_upload(file: file, store: true, threads: 4) do |progress|
    percentage = (progress[:uploaded].to_f / progress[:total] * 100).round(2)
    puts "Progress: #{percentage}% (#{progress[:uploaded]}/#{progress[:total]} bytes)"
  end
  response2 = response2.success

  puts "\nParallel upload complete!"
  puts "File UUID: #{response2['uuid']}"
ensure
  file&.close
  FileUtils.rm_f(test_file_path)
  puts "\nTest file cleaned up."
end

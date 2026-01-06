# frozen_string_literal: true

require_relative '../../lib/uploadcare'

# Load environment variables from .env file
env_file = File.expand_path('../../.env', __dir__)
if File.exist?(env_file)
  File.readlines(env_file).each do |line|
    next if line.start_with?('#') || line.strip.empty?

    key, value = line.strip.split('=', 2)
    ENV[key] = value if key && value
  end
end

# Configure Uploadcare
Uploadcare.configure do |config|
  config.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', nil)
end

# Example: Complete multipart upload flow
puts 'Example: Complete Multipart Upload Flow'
puts '=' * 50

client = Uploadcare::UploadClient.new

# Create a test file (11MB - minimum for multipart)
test_file_path = 'test_large_file.bin'
File.open(test_file_path, 'wb') do |f|
  # Write 11MB of random data
  (11 * 1024).times { f.write(SecureRandom.random_bytes(1024)) }
end

begin
  file = File.open(test_file_path, 'rb')
  file_size = file.size
  filename = File.basename(test_file_path)
  content_type = 'application/octet-stream'

  puts "\nStep 1: Start multipart upload"
  puts "File: #{filename} (#{file_size} bytes)"

  response = client.multipart_start(filename, file_size, content_type, store: true)
  upload_uuid = response['uuid']
  presigned_urls = response['parts']

  puts "Upload UUID: #{upload_uuid}"
  puts "Parts to upload: #{presigned_urls.length}"

  # Upload each part
  puts "\nStep 2: Upload parts"
  presigned_urls.each_with_index do |presigned_url, index|
    part_size = Uploadcare.configuration.multipart_chunk_size
    file.seek(index * part_size)
    part_data = file.read(part_size)

    break if part_data.nil? || part_data.empty?

    puts "Uploading part #{index + 1}/#{presigned_urls.length}..."
    client.multipart_upload_part(presigned_url, part_data)
    puts "  ✓ Part #{index + 1} uploaded successfully"
  end

  puts "\nAll parts uploaded successfully!"
  puts "Upload UUID: #{upload_uuid}"
  puts "\nNote: Use multipart_complete(uuid) to finalize the upload (Day 4)"
ensure
  file&.close
  FileUtils.rm_f(test_file_path)
end

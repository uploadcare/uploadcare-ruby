# frozen_string_literal: true

require_relative '../../lib/uploadcare'
require 'dotenv/load'

# Configure Uploadcare
Uploadcare.configure do |config|
  config.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY')
end

# Example 1: Upload from URL (sync mode - waits for completion)
puts 'Example 1: Upload from URL (sync mode)'
puts '=' * 50

source_url = ENV.fetch('UPLOADCARE_TEST_URL', 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/Cat_November_2010-1a.jpg/1200px-Cat_November_2010-1a.jpg')

client = Uploadcare::UploadClient.new
result = client.upload_from_url(source_url: source_url, store: true).success

puts 'Upload complete!'
puts "File UUID: #{result['uuid']}"
puts "Original filename: #{result['original_filename']}"
puts "File size: #{result['size']} bytes"
puts

# Example 2: Upload from URL (async mode - returns immediately)
puts 'Example 2: Upload from URL (async mode)'
puts '=' * 50

result = client.upload_from_url(source_url: source_url, async: true).success
token = result['token']

puts 'Upload started asynchronously'
puts "Token: #{token}"
puts

# Example 3: Check upload status
puts 'Example 3: Check upload status'
puts '=' * 50

status = client.upload_from_url_status(token: token).success

case status['status']
when 'success'
  puts 'Upload complete!'
  puts "File UUID: #{status['uuid']}"
when 'progress'
  puts 'Upload in progress'
when 'waiting'
  puts 'Upload waiting to start'
when 'error'
  puts "Upload failed: #{status['error']}"
end

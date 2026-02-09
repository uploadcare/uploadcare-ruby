# frozen_string_literal: true

require_relative '../../lib/uploadcare'
require 'dotenv/load'

# Configure Uploadcare
Uploadcare.configure do |config|
  config.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', 'YOUR_PUBLIC_KEY')
end

# Start an async upload
puts 'Starting async upload...'
puts '=' * 50

source_url = ENV.fetch('UPLOADCARE_TEST_URL', 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/Cat_November_2010-1a.jpg/1200px-Cat_November_2010-1a.jpg')

client = Uploadcare::UploadClient.new
result = client.upload_from_url(source_url: source_url, async: true)
unless result.success?
  warn "Upload failed: #{result.error_message}"
  exit 1
end

token = result.success['token']

puts "Upload token: #{token}"
puts

# Poll status multiple times
puts 'Polling upload status...'
puts '=' * 50

5.times do |i|
  status_result = client.upload_from_url_status(token: token)
  unless status_result.success?
    warn "Status check failed: #{status_result.error_message}"
    break
  end

  status = status_result.success

  puts "Poll #{i + 1}:"
  puts "  Status: #{status['status']}"

  case status['status']
  when 'success'
    puts "  UUID: #{status['uuid']}"
    puts "  Filename: #{status['original_filename']}"
    puts "  Size: #{status['size']} bytes"
    break
  when 'progress'
    puts "  Progress: #{status['progress']}%" if status['progress']
  when 'error'
    puts "  Error: #{status['error']}"
    break
  end

  sleep(1) unless i == 4
end

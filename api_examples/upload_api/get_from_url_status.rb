# frozen_string_literal: true

require_relative '../../lib/uploadcare'
require 'dotenv/load'

# Configure Uploadcare
Uploadcare.configure do |config|
  config.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', nil)
end

# Start an async upload
puts 'Starting async upload...'
puts '=' * 50

source_url = ENV.fetch('UPLOADCARE_TEST_URL', 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/Cat_November_2010-1a.jpg/1200px-Cat_November_2010-1a.jpg')

client = Uploadcare::UploadClient.new
result = client.upload_from_url(source_url: source_url, async: true).success
token = result['token']

puts "Upload token: #{token}"
puts

# Poll status multiple times
puts 'Polling upload status...'
puts '=' * 50

5.times do |i|
  status = client.upload_from_url_status(token: token).success

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

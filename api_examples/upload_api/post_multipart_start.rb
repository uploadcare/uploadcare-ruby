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

# Example: Start a multipart upload
puts 'Example: Start Multipart Upload'
puts '=' * 50

client = Uploadcare::UploadClient.new

# File information
filename = 'large_video.mp4'
file_size = 150 * 1024 * 1024 # 150MB
content_type = 'video/mp4'

# Start multipart upload
response = client.multipart_start(filename, file_size, content_type, store: true)

puts 'Multipart upload started!'
puts "Upload UUID: #{response['uuid']}"
puts "Number of parts: #{response['parts'].length}"
puts "\nPresigned URLs:"
response['parts'].each_with_index do |url, index|
  puts "  Part #{index + 1}: #{url[0..60]}..."
end

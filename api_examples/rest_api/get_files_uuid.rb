require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

uuid = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'

# Method 1: Using File resource directly
file = Uploadcare::File.new(uuid: uuid)
info = file.info(include: 'appdata,metadata')

puts "File Information:"
puts "UUID: #{info[:uuid]}"
puts "Filename: #{info[:original_filename]}"
puts "Size: #{info[:size]} bytes"
puts "MIME type: #{info[:mime_type]}"
puts "Stored: #{info[:datetime_stored].present?}"
puts "URL: #{info[:original_file_url]}"
puts "Metadata: #{info[:metadata]}"

# Method 2: Using client interface
client = Uploadcare.client
file_info = client.file_info(uuid: uuid)
puts file_info.inspect

# Method 3: With caching support (if cache configured)
file = Uploadcare::File.cached_find(uuid) if Uploadcare::File.respond_to?(:cached_find)
puts file.info.inspect if file

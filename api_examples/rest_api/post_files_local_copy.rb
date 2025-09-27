require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Create a local copy of a file
source_uuid = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'

# Create local copy
copied_file = Uploadcare::File.local_copy(
  source_uuid,
  store: true  # Store the copy immediately
)

puts "Original UUID: #{source_uuid}"
puts "Copy UUID: #{copied_file.uuid}"
puts "Copy URL: #{copied_file.original_file_url}"

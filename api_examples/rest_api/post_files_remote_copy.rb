require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Copy file to remote storage
source_uuid = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'
target_storage = 'my-s3-bucket'  # Preconfigured storage name

# Copy to remote storage
result = Uploadcare::File.remote_copy(
  source_uuid,
  target_storage,
  make_public: true,  # Make publicly accessible
  pattern: 'uploads/${year}/${month}/${filename}'  # Optional path pattern
)

puts "File copied to: #{result}"

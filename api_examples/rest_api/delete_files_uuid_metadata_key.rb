require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Delete specific metadata key from a file
uuid = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'
key = 'custom_key'

# Delete metadata key
result = Uploadcare::FileMetadata.delete(uuid, key)
puts "Metadata key '#{key}' deleted from file #{uuid}"

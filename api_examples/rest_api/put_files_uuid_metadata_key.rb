require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Update file metadata
uuid = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'
key = 'department'
value = 'marketing'

# Update metadata
result = Uploadcare::FileMetadata.update(uuid, key, value)
puts "Metadata updated: #{key} = #{value}"

# Retrieve metadata
metadata_value = Uploadcare::FileMetadata.show(uuid, key)
puts "Current value: #{metadata_value}"

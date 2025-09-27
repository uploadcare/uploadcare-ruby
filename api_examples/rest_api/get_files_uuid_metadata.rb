require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Get all metadata for a file
uuid = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'

# Get all metadata keys and values
metadata = Uploadcare::FileMetadata.index(uuid)

puts "File metadata for #{uuid}:"
metadata.each do |key, value|
  puts "  #{key}: #{value}"
end

# Alternative: Get metadata through file info
file = Uploadcare::File.new(uuid: uuid)
info = file.info(include: 'metadata')
puts "\nMetadata from file info:"
puts info[:metadata]
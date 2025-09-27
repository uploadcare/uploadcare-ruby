require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Method 1: Using the new query interface (Rails-style)
files = Uploadcare::File
  .where(stored: true, removed: false)
  .limit(100)
  .order(:datetime_uploaded, :desc)

files.each do |file|
  puts "UUID: #{file.uuid}"
  puts "Filename: #{file.original_filename}"
  puts "Size: #{file.size} bytes"
  puts "URL: #{file.original_file_url}"
  puts "---"
end

# Method 2: Using the traditional list method
file_list = Uploadcare::File.list(
  stored: true,
  removed: false,
  limit: 100,
  ordering: '-datetime_uploaded'
)

file_list.each { |file| puts file.inspect }

# Method 3: Using the new client interface
client = Uploadcare.client
files = client.list_files(stored: true, removed: false, limit: 100)
files.each { |file| puts file.inspect }

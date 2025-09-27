require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Get group information
group_uuid = 'GROUP_UUID~2'

# Method 1: Using Group resource
group = Uploadcare::Group.new(uuid: group_uuid)
info = group.info

puts "Group ID: #{info[:id]}"
puts "Files count: #{info[:files_count]}"
puts "Files:"
info[:files].each do |file|
  puts "  - #{file[:uuid]} (#{file[:original_filename]})"
end

# Method 2: Using client interface
client = Uploadcare.client
group_info = client.group_info(uuid: group_uuid)
puts group_info.inspect

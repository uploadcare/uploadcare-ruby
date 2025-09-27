require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Delete a file group
group_uuid = 'GROUP_UUID~2'

# Method 1: Using Group resource
group = Uploadcare::Group.new(uuid: group_uuid)
group.delete
puts "Group deleted: #{group_uuid}"

# Note: Files in the group are not deleted, only the group itself

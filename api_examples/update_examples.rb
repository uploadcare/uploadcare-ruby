#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to update all API examples to use the new API patterns

require 'fileutils'

# Define the new configuration header
NEW_CONFIG_HEADER = <<~RUBY
require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end
RUBY

# Example transformations for each file type
EXAMPLES = {
  'delete_files_storage.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Delete file from storage
uuid = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'

# Method 1: Using File resource
file = Uploadcare::File.new(uuid: uuid)
deleted_file = file.delete
puts "File deleted at: \#{deleted_file.datetime_removed}"

# Method 2: Using client interface
client = Uploadcare.client
result = client.delete_file(uuid: uuid)
puts result.inspect
  RUBY

  'delete_files_uuid_storage.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Remove file from storage (but keep metadata)
uuid = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'

# Using File resource
file = Uploadcare::File.new(uuid: uuid)
result = file.delete
puts "File removed from storage: \#{result.uuid}"
puts "Removal time: \#{result.datetime_removed}"
  RUBY

  'delete_files_uuid_metadata_key.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Delete specific metadata key from a file
uuid = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'
key = 'custom_key'

# Delete metadata key
result = Uploadcare::FileMetadata.delete(uuid, key)
puts "Metadata key '\#{key}' deleted from file \#{uuid}"
  RUBY

  'delete_groups_uuid.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Delete a file group
group_uuid = 'GROUP_UUID~2'

# Method 1: Using Group resource
group = Uploadcare::Group.new(uuid: group_uuid)
group.delete
puts "Group deleted: \#{group_uuid}"

# Note: Files in the group are not deleted, only the group itself
  RUBY

  'delete_webhooks_unsubscribe.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Delete/unsubscribe from a webhook
target_url = 'https://example.com/webhook/uploadcare'

# Delete webhook by target URL
Uploadcare::Webhook.delete(target_url)
puts "Webhook unsubscribed: \#{target_url}"
  RUBY

  'get_addons_aws_rekognition_detect_labels_execute_status.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Check AWS Rekognition label detection status
request_id = 'REQUEST_ID_FROM_EXECUTE'

# Check status
status = Uploadcare::AddOns.aws_rekognition_detect_labels_status(request_id)

if status[:status] == 'done'
  puts "Labels detected successfully"
  # Labels are now available in file's appdata
elsif status[:status] == 'error'
  puts "Detection failed: \#{status[:error]}"
else
  puts "Detection in progress..."
end
  RUBY

  'get_convert_document_status_token.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Check document conversion status
token = 123456  # Token from conversion request

# Check status
status = Uploadcare::DocumentConverter.status(token)

case status[:status]
when 'finished'
  puts "Conversion completed"
  puts "Result UUID: \#{status[:result][:uuid]}"
when 'processing'
  puts "Conversion in progress..."
when 'failed'
  puts "Conversion failed: \#{status[:error]}"
end
  RUBY

  'get_convert_video_status_token.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Check video conversion status
token = 123456  # Token from conversion request

# Check status
status = Uploadcare::VideoConverter.status(token)

case status[:status]
when 'finished'
  puts "Video conversion completed"
  puts "Result UUID: \#{status[:result][:uuid]}"
  puts "Thumbnails: \#{status[:result][:thumbnails_group_uuid]}"
when 'processing'
  puts "Conversion in progress..."
when 'failed'
  puts "Conversion failed: \#{status[:error]}"
end
  RUBY

  'get_groups.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# List file groups

# Method 1: Using Group.list
groups = Uploadcare::Group.list

groups.each do |group|
  puts "Group ID: \#{group.id}"
  puts "Files count: \#{group.files_count}"
  puts "Created: \#{group.datetime_created}"
  puts "---"
end

# Method 2: Using client interface
client = Uploadcare.client
groups = client.list_groups
groups.each { |group| puts group.inspect }
  RUBY

  'get_groups_uuid.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Get group information
group_uuid = 'GROUP_UUID~2'

# Method 1: Using Group resource
group = Uploadcare::Group.new(uuid: group_uuid)
info = group.info

puts "Group ID: \#{info[:id]}"
puts "Files count: \#{info[:files_count]}"
puts "Files:"
info[:files].each do |file|
  puts "  - \#{file[:uuid]} (\#{file[:original_filename]})"
end

# Method 2: Using client interface
client = Uploadcare.client
group_info = client.group_info(uuid: group_uuid)
puts group_info.inspect
  RUBY

  'get_project.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Get project information

# Method 1: Using Project resource
project = Uploadcare::Project.show

puts "Project name: \#{project.name}"
puts "Public key: \#{project.pub_key}"
puts "Autostore enabled: \#{project.autostore_enabled}"
puts "Collaborators: \#{project.collaborators.count}"

# Method 2: Using client interface
client = Uploadcare.client
project_info = client.project_info
puts project_info.inspect
  RUBY

  'get_webhooks.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# List all webhooks

# Method 1: Using Webhook.list
webhooks = Uploadcare::Webhook.list

webhooks.each do |webhook|
  puts "ID: \#{webhook.id}"
  puts "Target URL: \#{webhook.target_url}"
  puts "Event: \#{webhook.event}"
  puts "Active: \#{webhook.is_active}"
  puts "---"
end

# Method 2: Using client interface
client = Uploadcare.client
webhooks = client.list_webhooks
webhooks.each { |webhook| puts webhook.inspect }
  RUBY

  'post_addons_aws_rekognition_detect_labels_execute.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Execute AWS Rekognition label detection
uuid = 'FILE_UUID'

# Execute detection
result = Uploadcare::AddOns.aws_rekognition_detect_labels(uuid)
request_id = result[:request_id]

puts "Detection started with request ID: \#{request_id}"
puts "Check status with: Uploadcare::AddOns.aws_rekognition_detect_labels_status('\#{request_id}')"

# Results will be available in file's appdata when complete
  RUBY

  'post_addons_remove_bg_execute.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Remove background from image
uuid = 'FILE_UUID'

# Execute background removal with options
result = Uploadcare::AddOns.remove_bg(
  uuid,
  crop: true,           # Crop to object
  type_level: '2',      # Accuracy level (1 or 2)
  type: 'person',       # Object type: person, product, car
  scale: '100%',        # Output scale
  position: 'center'    # Crop position if cropping
)

request_id = result[:request_id]
puts "Background removal started with request ID: \#{request_id}"

# Check status
status = Uploadcare::AddOns.remove_bg_status(request_id)
if status[:status] == 'done'
  puts "Result file UUID: \#{status[:result][:file_id]}"
end
  RUBY

  'post_addons_uc_clamav_virus_scan_execute.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Scan file for viruses
uuid = 'FILE_UUID'

# Execute virus scan with auto-purge if infected
result = Uploadcare::AddOns.uc_clamav_virus_scan(
  uuid,
  purge_infected: true  # Automatically delete if infected
)

request_id = result[:request_id]
puts "Virus scan started with request ID: \#{request_id}"

# Check status
status = Uploadcare::AddOns.uc_clamav_virus_scan_status(request_id)
if status[:status] == 'done'
  # Check file's appdata for scan results
  file = Uploadcare::File.new(uuid: uuid)
  info = file.info(include: 'appdata')
  scan_data = info[:appdata][:uc_clamav_virus_scan][:data]
  
  if scan_data[:infected]
    puts "File infected with: \#{scan_data[:infected_with]}"
  else
    puts "File is clean"
  end
end
  RUBY

  'post_convert_document.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Convert document to different format
uuid = 'DOCUMENT_UUID'

# Check supported formats first
info = Uploadcare::DocumentConverter.info(uuid)
puts "Current format: \#{info[:format][:name]}"
puts "Can convert to: \#{info[:format][:conversion_formats].map { |f| f[:name] }.join(', ')}"

# Convert document
result = Uploadcare::DocumentConverter.convert(
  [
    {
      uuid: uuid,
      format: 'pdf',    # Target format
      page: 1           # For image outputs, specific page number
    }
  ],
  store: true  # Store the result
)

token = result[:result].first[:token]
puts "Conversion started with token: \#{token}"

# Check status
status = Uploadcare::DocumentConverter.status(token)
if status[:status] == 'finished'
  puts "Converted file UUID: \#{status[:result][:uuid]}"
end
  RUBY

  'post_convert_video.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Convert video with various options
uuid = 'VIDEO_UUID'

# Convert video
result = Uploadcare::VideoConverter.convert(
  [
    {
      uuid: uuid,
      format: 'mp4',           # Output format: mp4, webm, ogg
      quality: 'normal',       # Quality: normal, better, best, lighter, lightest
      size: {
        resize_mode: 'change_ratio',  # preserve_ratio, change_ratio, scale_crop, add_padding
        width: '1280',
        height: '720'
      },
      cut: {
        start_time: '0:0:0.0',  # Start time
        length: '0:1:0.0'       # Duration (or 'end')
      },
      thumbs: {
        N: 10,      # Number of thumbnails
        number: 1   # Specific thumbnail index
      }
    }
  ],
  store: true
)

token = result[:result].first[:token]
uuid_result = result[:result].first[:uuid]
thumbnails = result[:result].first[:thumbnails_group_uuid]

puts "Conversion started"
puts "Token: \#{token}"
puts "Result UUID: \#{uuid_result}"
puts "Thumbnails group: \#{thumbnails}"

# Check status
status = Uploadcare::VideoConverter.status(token)
if status[:status] == 'finished'
  puts "Video conversion completed!"
end
  RUBY

  'post_files_local_copy.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Create a local copy of a file
source_uuid = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'

# Create local copy
copied_file = Uploadcare::File.local_copy(
  source_uuid,
  store: true  # Store the copy immediately
)

puts "Original UUID: \#{source_uuid}"
puts "Copy UUID: \#{copied_file.uuid}"
puts "Copy URL: \#{copied_file.original_file_url}"
  RUBY

  'post_files_remote_copy.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Copy file to remote storage
source_uuid = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'
target_storage = 'my-s3-bucket'  # Preconfigured storage name

# Copy to remote storage
result = Uploadcare::File.remote_copy(
  source_uuid,
  target_storage,
  make_public: true,  # Make publicly accessible
  pattern: 'uploads/\${year}/\${month}/\${filename}'  # Optional path pattern
)

puts "File copied to: \#{result}"
  RUBY

  'post_groups.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Create a file group
file_uuids = [
  '1bac376c-aa7e-4356-861b-dd2657b5bfd2',
  'a4b9db2f-1591-4f4c-8f68-94018924525d'
]

# Method 1: Using Group.create
group = Uploadcare::Group.create(file_uuids)
puts "Group created with ID: \#{group.id}"
puts "Contains \#{group.files_count} files"

# Method 2: Using client interface
client = Uploadcare.client
group = client.create_group(file_uuids)
puts group.inspect
  RUBY

  'post_webhooks.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Create a new webhook
webhook = Uploadcare::Webhook.create(
  target_url: 'https://example.com/webhook/uploadcare',
  event: 'file.uploaded',  # Events: file.uploaded, file.stored, file.deleted, etc.
  is_active: true,
  signing_secret: 'your_webhook_secret',  # For signature verification
  version: '0.7'
)

puts "Webhook created"
puts "ID: \#{webhook.id}"
puts "Target: \#{webhook.target_url}"
puts "Event: \#{webhook.event}"
puts "Active: \#{webhook.is_active}"
  RUBY

  'put_files_storage.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Batch store multiple files
uuids = [
  '1bac376c-aa7e-4356-861b-dd2657b5bfd2',
  'a4b9db2f-1591-4f4c-8f68-94018924525d'
]

# Batch store
result = Uploadcare::File.batch_store(uuids)

if result.status == 'success'
  puts "Successfully stored \#{result.result.count} files:"
  result.result.each do |file|
    puts "  - \#{file.uuid}: stored at \#{file.datetime_stored}"
  end
end

# Handle any problems
if result.problems.any?
  puts "Problems encountered:"
  result.problems.each do |uuid, error|
    puts "  - \#{uuid}: \#{error}"
  end
end
  RUBY

  'put_files_uuid_storage.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Store a single file
uuid = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'

# Method 1: Using File resource
file = Uploadcare::File.new(uuid: uuid)
stored_file = file.store
puts "File stored at: \#{stored_file.datetime_stored}"

# Method 2: Using client interface
client = Uploadcare.client
result = client.store_file(uuid: uuid)
puts result.inspect
  RUBY

  'put_files_uuid_metadata_key.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Update file metadata
uuid = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'
key = 'department'
value = 'marketing'

# Update metadata
result = Uploadcare::FileMetadata.update(uuid, key, value)
puts "Metadata updated: \#{key} = \#{value}"

# Retrieve metadata
metadata_value = Uploadcare::FileMetadata.show(uuid, key)
puts "Current value: \#{metadata_value}"
  RUBY

  'put_groups_uuid_storage.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Store all files in a group
group_uuid = 'GROUP_UUID~2'

# Store group (stores all contained files)
Uploadcare::Group.store(group_uuid)
puts "Group and all its files have been stored"
  RUBY

  'put_webhooks_id.rb' => <<~RUBY
#{NEW_CONFIG_HEADER}
# Update an existing webhook
webhook_id = 123  # Webhook ID from creation or list

# Method 1: Using Webhook.update class method
updated_webhook = Uploadcare::Webhook.update(
  webhook_id,
  target_url: 'https://example.com/webhook/new',
  event: 'file.stored',
  is_active: true,
  signing_secret: 'new_secret'
)

puts "Webhook updated"
puts "New target: \#{updated_webhook.target_url}"
puts "New event: \#{updated_webhook.event}"

# Method 2: Using instance method
webhook = Uploadcare::Webhook.list.find { |w| w.id == webhook_id }
webhook.update(
  target_url: 'https://example.com/webhook/updated',
  is_active: false
)
puts "Webhook deactivated"
  RUBY
}

# Process each example file
Dir.glob('api_examples/rest_api/*.rb').each do |file|
  filename = File.basename(file)
  
  if EXAMPLES.key?(filename)
    puts "Updating #{filename}..."
    File.write(file, EXAMPLES[filename])
  else
    puts "Skipping #{filename} (no transformation defined)"
  end
end

puts "\nUpdating upload API examples..."

# Upload API examples
UPLOAD_EXAMPLES = {
  'upload_from_url.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Upload file from URL

# Synchronous upload (waits for completion)
file = Uploadcare::Uploader.upload_from_url(
  'https://example.com/image.jpg',
  store: 'auto'  # auto, true, or false
)

puts "File uploaded:"
puts "UUID: \#{file.uuid}"
puts "URL: \#{file.original_file_url}"

# Asynchronous upload (returns immediately)
token = Uploadcare::Uploader.upload_from_url(
  'https://example.com/large-file.zip',
  async: true,
  store: true
)

puts "Upload started with token: \#{token}"

# Check async upload status
status = Uploadcare::Uploader.get_upload_from_url_status(token)
case status[:status]
when 'success'
  puts "Upload complete: \#{status[:uuid]}"
when 'error'
  puts "Upload failed: \#{status[:error]}"
when 'progress'
  percent = (status[:done].to_f / status[:total] * 100).round(2)
  puts "Upload progress: \#{percent}%"
end
  RUBY

  'upload_file.rb' => <<~RUBY,
#{NEW_CONFIG_HEADER}
# Upload local file

# From file path
file = File.open('path/to/image.jpg')
uploaded = Uploadcare::Uploader.upload(
  file,
  store: true,
  metadata: {
    source: 'api_example',
    user_id: '123'
  }
)

puts "File uploaded:"
puts "UUID: \#{uploaded.uuid}"
puts "URL: \#{uploaded.original_file_url}"
puts "Size: \#{uploaded.size} bytes"

file.close

# From string/IO
require 'stringio'
content = StringIO.new("Hello, Uploadcare!")
uploaded = Uploadcare::Uploader.upload(content, store: false)
puts "String uploaded: \#{uploaded.uuid}"
  RUBY

  'multipart_upload.rb' => <<~RUBY
#{NEW_CONFIG_HEADER}
# Multipart upload for large files (>100MB)

large_file = File.open('path/to/large-video.mp4')

# Upload with progress tracking
uploaded = Uploadcare::Uploader.multipart_upload(
  large_file,
  store: true,
  metadata: {
    type: 'video',
    duration: '01:23:45'
  }
) do |progress|
  percent = (progress[:offset].to_f / progress[:object].size * 100).round(2)
  puts "Upload progress: \#{percent}% (chunk \#{progress[:link_id] + 1}/\#{progress[:links_count]})"
end

puts "Upload complete!"
puts "UUID: \#{uploaded.uuid}"
puts "URL: \#{uploaded.original_file_url}"

large_file.close
  RUBY
}

Dir.glob('api_examples/upload_api/*.rb').each do |file|
  filename = File.basename(file)
  
  if UPLOAD_EXAMPLES.key?(filename)
    puts "Updating #{filename}..."
    File.write(file, UPLOAD_EXAMPLES[filename])
  end
end

puts "\nAll API examples have been updated!"
# Uploadcare Ruby SDK Examples

This document provides comprehensive examples for all features of the Uploadcare Ruby SDK v3.5+.

## Table of Contents
- [Configuration](#configuration)
- [File Upload](#file-upload)
- [File Management](#file-management)
- [Batch Operations](#batch-operations)
- [Groups](#groups)
- [Webhooks](#webhooks)
- [Add-Ons](#add-ons)
- [Conversions](#conversions)
- [Secure Delivery](#secure-delivery)
- [Error Handling](#error-handling)

## Configuration

### Basic Configuration
```ruby
# Option 1: Configure globally
Uploadcare.configure do |config|
  config.public_key = 'your_public_key'
  config.secret_key = 'your_secret_key'
  config.max_request_tries = 5  # optional
  config.base_request_sleep = 1 # optional
  config.max_request_sleep = 60 # optional
end

# Option 2: Environment variables (automatic)
# Set UPLOADCARE_PUBLIC_KEY and UPLOADCARE_SECRET_KEY

# Option 3: Per-client configuration
client = Uploadcare.client(
  public_key: 'your_public_key',
  secret_key: 'your_secret_key'
)
```

## File Upload

### Basic Upload
```ruby
# Upload from file
file = File.open('path/to/image.jpg')
uploaded = Uploadcare::Uploader.upload(file, store: 'auto')
puts uploaded.uuid
puts uploaded.original_file_url

# Upload from URL
uploaded = Uploadcare::Uploader.upload_from_url('https://example.com/image.jpg')

# Upload from string/IO
require 'stringio'
io = StringIO.new("Hello, World!")
uploaded = Uploadcare::Uploader.upload(io, store: true)
```

### Upload with Metadata
```ruby
file = File.open('document.pdf')
uploaded = Uploadcare::Uploader.upload(
  file,
  store: true,
  metadata: {
    department: 'finance',
    document_type: 'invoice',
    year: '2024'
  }
)
```

### Multipart Upload for Large Files
```ruby
large_file = File.open('video.mp4') # > 100MB
uploaded = Uploadcare::Uploader.multipart_upload(large_file, store: true) do |progress_info|
  percent = (progress_info[:offset].to_f / progress_info[:object].size * 100).round(2)
  puts "Upload progress: #{percent}%"
end
```

### Upload Multiple Files
```ruby
files = [
  File.open('image1.jpg'),
  File.open('image2.jpg'),
  File.open('document.pdf')
]
results = Uploadcare::Uploader.upload_files(files, store: 'auto')
results.each { |file| puts "Uploaded: #{file.uuid}" }
```

### Async Upload from URL
```ruby
# Start async upload
token = Uploadcare::Uploader.upload_from_url('https://example.com/large-file.zip', async: true)

# Check status
status = Uploadcare::Uploader.get_upload_from_url_status(token)
if status[:status] == 'success'
  puts "File uploaded: #{status[:uuid]}"
elsif status[:status] == 'error'
  puts "Upload failed: #{status[:error]}"
else
  puts "Upload in progress..."
end
```

## File Management

### Get File Information
```ruby
# Using File resource
file = Uploadcare::File.new(uuid: 'dc99200d-9bd6-4b43-bfa9-aa7bfaefca40')
info = file.info(include: 'appdata')

puts info[:original_filename]
puts info[:size]
puts info[:mime_type]
puts info[:datetime_uploaded]

# Access metadata
puts info[:metadata]

# Access app data (if any add-ons were applied)
puts info[:appdata]
```

### Store and Delete Files
```ruby
# Store a file permanently
file = Uploadcare::File.new(uuid: 'FILE_UUID')
stored = file.store
puts "Stored at: #{stored.datetime_stored}"

# Delete a file
deleted = file.delete
puts "Deleted at: #{deleted.datetime_removed}"

# Note: Deleted file metadata is kept permanently
```

### List Files with Filtering
```ruby
# List all stored files
files = Uploadcare::File.list(
  limit: 100,
  stored: true,
  ordering: '-datetime_uploaded'
)

files.each do |file|
  puts "#{file.original_filename} - #{file.size} bytes"
end

# List files uploaded after specific date
files = Uploadcare::File.list(
  from: '2024-01-01T00:00:00Z',
  ordering: 'datetime_uploaded'
)

# Pagination
page1 = Uploadcare::File.list(limit: 10)
page2 = page1.next_page if page1.next_page
```

### Copy Files
```ruby
# Local copy (within same project)
source_uuid = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'
copied = Uploadcare::File.local_copy(source_uuid, store: true)
puts "New file UUID: #{copied.uuid}"

# Remote copy (to external storage)
result = Uploadcare::File.remote_copy(
  source_uuid,
  'my-s3-storage',  # preconfigured storage name
  make_public: true
)
puts "File copied to: #{result}"
```

### File Metadata Management
```ruby
uuid = 'FILE_UUID'

# Get all metadata
metadata = Uploadcare::FileMetadata.index(uuid)
puts metadata

# Get specific metadata value
value = Uploadcare::FileMetadata.show(uuid, 'department')
puts "Department: #{value}"

# Update metadata
Uploadcare::FileMetadata.update(uuid, 'status', 'approved')

# Delete metadata key
Uploadcare::FileMetadata.delete(uuid, 'temp_flag')
```

## Batch Operations

### Batch Store
```ruby
uuids = [
  'dc99200d-9bd6-4b43-bfa9-aa7bfaefca40',
  'a4b9db2f-1591-4f4c-8f68-94018924525d',
  '8f64f313-e6b1-4731-96c0-6751f1e7a50a'
]

result = Uploadcare::File.batch_store(uuids)

if result.status == 'success'
  result.result.each do |file|
    puts "Stored: #{file.uuid}"
  end
end

# Handle any problems
result.problems.each do |uuid, error|
  puts "Failed to store #{uuid}: #{error}"
end
```

### Batch Delete
```ruby
uuids = ['uuid1', 'uuid2', 'uuid3']
result = Uploadcare::File.batch_delete(uuids)

if result.status == 'success'
  puts "Successfully deleted #{result.result.count} files"
end
```

## Groups

### Create and Manage Groups
```ruby
# Create a group from file UUIDs
file_uuids = [
  '134dc30c-093e-4f48-a5b9-966fe9cb1d01',
  '134dc30c-093e-4f48-a5b9-966fe9cb1d02'
]
group = Uploadcare::Group.create(file_uuids)
puts "Group created: #{group.id}"

# Get group info
group = Uploadcare::Group.new(uuid: 'GROUP_UUID~2')
info = group.info
puts "Files in group: #{info[:files_count]}"

# Store all files in group
Uploadcare::Group.store(group.id)

# Delete group (files remain)
group.delete
```

### List Groups
```ruby
groups = Uploadcare::Group.list
groups.each do |group|
  puts "Group #{group.id} has #{group.files_count} files"
end
```

## Webhooks

### Create and Manage Webhooks
```ruby
# Create webhook
webhook = Uploadcare::Webhook.create(
  target_url: 'https://example.com/webhook/uploadcare',
  event: 'file.uploaded',
  is_active: true,
  signing_secret: 'webhook_secret_key'
)
puts "Webhook created with ID: #{webhook.id}"

# Update webhook
updated = Uploadcare::Webhook.update(
  webhook.id,
  target_url: 'https://example.com/webhook/new',
  event: 'file.stored',
  is_active: true
)

# Or update instance
webhook.update(
  target_url: 'https://example.com/webhook/updated',
  is_active: false
)

# List all webhooks
webhooks = Uploadcare::Webhook.list
webhooks.each do |w|
  puts "#{w.event} -> #{w.target_url} (#{w.is_active ? 'active' : 'inactive'})"
end

# Delete webhook
Uploadcare::Webhook.delete('https://example.com/webhook/uploadcare')
```

### Verify Webhook Signatures
```ruby
# In your webhook endpoint
webhook_body = request.body.read
x_uc_signature = request.headers['X-Uc-Signature']
signing_secret = 'webhook_secret_key'

is_valid = Uploadcare::Param::WebhookSignatureVerifier.valid?(
  webhook_body: webhook_body,
  x_uc_signature_header: x_uc_signature,
  signing_secret: signing_secret
)

if is_valid
  # Process webhook
  data = JSON.parse(webhook_body)
  puts "File uploaded: #{data['data']['uuid']}"
else
  # Invalid signature
  halt 401, 'Invalid signature'
end
```

## Add-Ons

### AWS Rekognition
```ruby
# Detect labels in image
result = Uploadcare::AddOns.aws_rekognition_detect_labels('FILE_UUID')
request_id = result[:request_id]

# Check status
status = Uploadcare::AddOns.aws_rekognition_detect_labels_status(request_id)
if status[:status] == 'done'
  # Labels are now in file's appdata
  file = Uploadcare::File.new(uuid: 'FILE_UUID')
  info = file.info(include: 'appdata')
  labels = info[:appdata][:aws_rekognition_detect_labels]
  
  labels[:data][:Labels].each do |label|
    puts "#{label[:Name]} - #{label[:Confidence]}%"
  end
end

# Detect moderation labels
result = Uploadcare::AddOns.aws_rekognition_detect_moderation_labels('FILE_UUID')
status = Uploadcare::AddOns.aws_rekognition_detect_moderation_labels_status(result[:request_id])
```

### Remove Background
```ruby
# Remove background from image
result = Uploadcare::AddOns.remove_bg(
  'FILE_UUID',
  crop: true,           # crop to object
  type_level: '2',       # accuracy level
  type: 'person',        # object type
  scale: '100%',         # output scale
  position: 'center'     # crop position
)

# Check status
status = Uploadcare::AddOns.remove_bg_status(result[:request_id])
if status[:status] == 'done'
  puts "Result file: #{status[:result][:file_id]}"
end
```

### Virus Scanning
```ruby
# Scan file for viruses
result = Uploadcare::AddOns.uc_clamav_virus_scan(
  'FILE_UUID',
  purge_infected: true  # auto-delete if infected
)

# Check status
status = Uploadcare::AddOns.uc_clamav_virus_scan_status(result[:request_id])
if status[:status] == 'done'
  file = Uploadcare::File.new(uuid: 'FILE_UUID')
  info = file.info(include: 'appdata')
  scan_result = info[:appdata][:uc_clamav_virus_scan]
  
  if scan_result[:data][:infected]
    puts "File infected with: #{scan_result[:data][:infected_with]}"
  else
    puts "File is clean"
  end
end
```

## Conversions

### Document Conversion
```ruby
# Check supported formats
info = Uploadcare::DocumentConverter.info('DOCUMENT_UUID')
puts "Current format: #{info[:format][:name]}"
puts "Can convert to: #{info[:format][:conversion_formats].map { |f| f[:name] }.join(', ')}"

# Convert document
result = Uploadcare::DocumentConverter.convert(
  [
    {
      uuid: 'DOCUMENT_UUID',
      format: 'pdf',
      page: 1  # for image output formats
    }
  ],
  store: true
)

# Check conversion status
token = result[:result].first[:token]
status = Uploadcare::DocumentConverter.status(token)

if status[:status] == 'finished'
  puts "Converted file: #{status[:result][:uuid]}"
elsif status[:status] == 'failed'
  puts "Conversion failed: #{status[:error]}"
end

# Or use File instance method
file = Uploadcare::File.new(uuid: 'DOCUMENT_UUID')
converted = file.convert_document({ format: 'png', page: 1 }, store: true)
```

### Video Conversion
```ruby
# Convert video with various options
result = Uploadcare::VideoConverter.convert(
  [
    {
      uuid: 'VIDEO_UUID',
      format: 'mp4',
      quality: 'best',
      size: {
        resize_mode: 'change_ratio',
        width: '1920',
        height: '1080'
      },
      cut: {
        start_time: '0:0:10.0',
        length: '0:1:00.0'
      },
      thumbs: {
        N: 10,      # number of thumbnails
        number: 1   # specific thumbnail
      }
    }
  ],
  store: true
)

# Check status
token = result[:result].first[:token]
status = Uploadcare::VideoConverter.status(token)

if status[:status] == 'finished'
  puts "Converted video: #{status[:result][:uuid]}"
  puts "Thumbnails: #{status[:result][:thumbnails_group_uuid]}"
end

# Using File instance
file = Uploadcare::File.new(uuid: 'VIDEO_UUID')
converted = file.convert_video(
  {
    format: 'webm',
    quality: 'lighter',
    size: { resize_mode: 'scale_crop', width: '640', height: '480' }
  },
  store: true
)
```

## Secure Delivery

### Generate Authenticated URLs
```ruby
# Configure Akamai generator
generator = Uploadcare::SignedUrlGenerators::AkamaiGenerator.new(
  cdn_host: 'cdn.example.com',
  secret_key: 'your_akamai_secret',
  ttl: 3600,  # 1 hour
  algorithm: 'sha256'
)

# Generate basic authenticated URL
uuid = 'a7d5645e-5cd7-4046-819f-a6a2933bafe3'
secure_url = generator.generate_url(uuid)
puts secure_url
# => https://cdn.example.com/a7d5645e-5cd7-4046-819f-a6a2933bafe3/?token=exp=...

# Generate with custom ACL
secure_url = generator.generate_url(uuid, '/files/*')

# Generate wildcard URL
secure_url = generator.generate_url(uuid, wildcard: true)
```

## Error Handling

### Handle API Errors
```ruby
begin
  file = Uploadcare::File.new(uuid: 'non-existent-uuid')
  file.store
rescue Uploadcare::Exception::RequestError => e
  puts "Request failed: #{e.message}"
  puts "Error code: #{e.error_code}" if e.respond_to?(:error_code)
rescue Uploadcare::Exception::AuthError => e
  puts "Authentication failed: #{e.message}"
rescue Uploadcare::Exception::ThrottleError => e
  puts "Rate limited. Retry after: #{e.retry_after} seconds"
rescue Uploadcare::Exception::RetryError => e
  puts "Max retries exceeded: #{e.message}"
end
```

### Handle Upload Errors
```ruby
begin
  file = File.open('large_file.bin')
  uploaded = Uploadcare::Uploader.upload(file, store: true)
rescue Uploadcare::Exception::ConversionError => e
  puts "Conversion failed: #{e.message}"
rescue StandardError => e
  puts "Upload failed: #{e.message}"
end
```

### Validation and Safe Operations
```ruby
# Validate webhook signature
begin
  is_valid = Uploadcare::Param::WebhookSignatureVerifier.valid?(
    webhook_body: body,
    x_uc_signature_header: signature,
    signing_secret: secret
  )
rescue => e
  puts "Validation error: #{e.message}"
  is_valid = false
end

# Safe batch operations
result = Uploadcare::File.batch_store(uuids)
if result.success?
  puts "All files stored successfully"
else
  result.problems.each do |uuid, error|
    puts "#{uuid}: #{error}"
  end
end
```

## Advanced Usage

### Custom Configuration Per Request
```ruby
# Create client with custom config
custom_client = Uploadcare.client(
  public_key: 'different_key',
  secret_key: 'different_secret',
  max_request_tries: 10
)

# Use custom client for operations
files = custom_client.list_files(limit: 5)
```

### Working with Rails
```ruby
# In config/initializers/uploadcare.rb
Uploadcare.configure do |config|
  config.public_key = Rails.application.credentials.uploadcare[:public_key]
  config.secret_key = Rails.application.credentials.uploadcare[:secret_key]
end

# In your model
class Document < ApplicationRecord
  after_create :upload_to_uploadcare
  
  private
  
  def upload_to_uploadcare
    return unless file.attached?
    
    uploaded = Uploadcare::Uploader.upload(
      file.download,
      store: true,
      metadata: { document_id: id }
    )
    
    update(uploadcare_uuid: uploaded.uuid)
  end
end

# In your controller
class DocumentsController < ApplicationController
  def show
    @document = Document.find(params[:id])
    @file = Uploadcare::File.new(uuid: @document.uploadcare_uuid)
    @file_info = @file.info
  end
end
```

### Using with Background Jobs
```ruby
# app/jobs/upload_job.rb
class UploadJob < ApplicationJob
  queue_as :default
  
  def perform(file_path, metadata = {})
    file = File.open(file_path)
    uploaded = Uploadcare::Uploader.upload(file, store: true, metadata: metadata)
    
    # Process uploaded file
    ProcessFileJob.perform_later(uploaded.uuid)
  ensure
    file&.close
  end
end

# app/jobs/process_file_job.rb
class ProcessFileJob < ApplicationJob
  def perform(uuid)
    file = Uploadcare::File.new(uuid: uuid)
    
    # Apply add-ons
    Uploadcare::AddOns.aws_rekognition_detect_labels(uuid)
    
    # Convert if needed
    if file.info[:mime_type].start_with?('video/')
      file.convert_video({ format: 'mp4', quality: 'normal' }, store: true)
    end
  end
end
```

## Testing

### Mocking Uploadcare in Tests
```ruby
# spec/support/uploadcare_helpers.rb
module UploadcareHelpers
  def stub_uploadcare_upload
    allow(Uploadcare::Uploader).to receive(:upload).and_return(
      double(
        uuid: 'test-uuid-1234',
        original_file_url: 'https://ucarecdn.com/test-uuid-1234/test.jpg'
      )
    )
  end
  
  def stub_uploadcare_file_info
    allow_any_instance_of(Uploadcare::File).to receive(:info).and_return(
      {
        uuid: 'test-uuid-1234',
        original_filename: 'test.jpg',
        size: 1024,
        mime_type: 'image/jpeg'
      }
    )
  end
end

# In your specs
RSpec.describe DocumentsController, type: :controller do
  include UploadcareHelpers
  
  before do
    stub_uploadcare_upload
    stub_uploadcare_file_info
  end
  
  it 'uploads file to Uploadcare' do
    post :create, params: { file: fixture_file_upload('test.jpg') }
    expect(response).to be_successful
  end
end
```

## Debugging

### Enable Request Logging
```ruby
Uploadcare.configure do |config|
  config.logger = Logger.new(STDOUT)
  config.log_level = :debug
end

# Now all requests/responses will be logged
file = Uploadcare::File.new(uuid: 'test')
file.info  # Will log request details
```

### Inspect Response Headers
```ruby
# Most operations return response objects with headers
result = Uploadcare::File.list
puts result.response.headers['X-RateLimit-Remaining']
```

## Performance Tips

1. **Use batch operations** when working with multiple files
2. **Enable caching** for file info requests in production
3. **Use multipart upload** for files larger than 100MB
4. **Implement retry logic** for network errors
5. **Use webhooks** instead of polling for async operations
6. **Store file UUIDs** in your database to avoid repeated API calls

## Migration from v2.x to v3.x

If you're upgrading from v2.x, here are the main changes:

```ruby
# Old (v2.x)
@api = Uploadcare::Api.new
@api.upload(file)
@api.file('uuid')

# New (v3.x) - Using resources directly
Uploadcare::Uploader.upload(file)
Uploadcare::File.new(uuid: 'uuid').info

# Or using the new client
client = Uploadcare.client
client.upload_file(file)
client.file_info(uuid: 'uuid')
```

## Support

For more information:
- [API Documentation](https://uploadcare.com/api-refs/)
- [Ruby SDK GitHub](https://github.com/uploadcare/uploadcare-ruby)
- [Support](https://uploadcare.com/support/)
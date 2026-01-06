# Ruby integration for Uploadcare

![license](https://img.shields.io/badge/license-MIT-brightgreen.svg)
[![Build Status][actions-img]][actions-badge]
[![Uploadcare stack on StackShare][stack-img]][stack]

[actions-badge]: https://github.com/uploadcare/uploadcare-ruby/actions/workflows/ruby.yml
[actions-img]: https://github.com/uploadcare/uploadcare-ruby/actions/workflows/ruby.yml/badge.svg
[coverals-img]: https://coveralls.io/repos/github/uploadcare/uploadcare-ruby/badge.svg?branch=main
[coverals]: https://coveralls.io/github/uploadcare/uploadcare-ruby?branch=main
[stack-img]: https://img.shields.io/badge/tech-stack-0690fa.svg?style=flat
[stack]: https://stackshare.io/uploadcare/stacks/

Uploadcare Ruby integration handles uploads and further operations with files by
wrapping Upload and REST APIs.

- [Installation](#installation)
- [Usage](#usage)
  - [Uploading files](#uploading-files)
    - [Uploading and storing a single file](#uploading-and-storing-a-single-file)
    - [Multiple ways to upload files](#multiple-ways-to-upload-files)
    - [Uploading options](#uploading-options)
  - [File management](#file-management)
    - [File](#file)
    - [FileList](#filelist)
    - [Pagination](#pagination)
    - [Custom File Metadata](#custom-file-metadata)
    - [Group](#group)
    - [GroupList](#grouplist)
    - [Webhook](#webhook)
    - [Add-Ons](#add-ons)
    - [Project](#project)
    - [Conversion](#conversion)
- [Useful links](#useful-links)

## Requirements

- Ruby 3.3+ (compatible with Rails main)

## Compatibility

Note that `uploadcare-ruby` **3.x** is not backward compatible with
**[2.x](https://github.com/uploadcare/uploadcare-ruby/tree/v2.x)**.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "uploadcare-ruby"
```

And then execute:

    $ bundle

If already not, create your project in [Uploadcare dashboard](https://app.uploadcare.com/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-ruby) and copy
its [API keys](https://app.uploadcare.com/projects/-/api-keys/) from there.

Set your Uploadcare keys in config file or through environment variables:

```bash
export UPLOADCARE_PUBLIC_KEY=your_public_key
export UPLOADCARE_SECRET_KEY=your_private_key
```

Or configure your app yourself if you are using different way of storing keys.
Gem configuration is available in `Uploadcare.configuration`. Full list of
settings can be seen in [`lib/uploadcare/configuration.rb`](lib/uploadcare/configuration.rb)

```ruby
# your_config_initializer_file.rb
Uploadcare.configuration.public_key = "your_public_key"
Uploadcare.configuration.secret_key = "your_private_key"
```

### CDN Configuration

Uploadcare supports custom CDN domains and automatic subdomain generation. You can configure these options:

```ruby
Uploadcare.configure do |config|
  # Enable automatic subdomain generation (default: false)
  config.use_subdomains = true

  # Base domain for subdomain generation (default: 'https://ucarecd.net/')
  config.cdn_base_postfix = 'https://ucarecd.net/'

  # Default CDN base URL (default: 'https://ucarecdn.com/')
  config.default_cdn_base = 'https://ucarecdn.com/'
end

# Get the generated CNAME for your account
Uploadcare.configuration.custom_cname
# => "a1b2c3d4e5" (10-character hash based on your public key)

# Get the active CDN base (respects use_subdomains setting)
Uploadcare.configuration.cdn_base.call
# => "https://a1b2c3d4e5.ucarecd.net/" (if use_subdomains is true)
# => "https://ucarecdn.com/" (if use_subdomains is false)
```

## Usage

This section contains practical usage examples. Please note, everything that
follows gets way more clear once you've looked through our
[docs](https://uploadcare.com/docs/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-ruby)
and [Upload](https://uploadcare.com/api-refs/upload-api/) and [REST](https://uploadcare.com/api-refs/rest-api/) API refs.

You can also find an example project [here](https://github.com/uploadcare/uploadcare-rails-example).

In examples we’re going to use `demo.ucarecd.net` domain. Check your project's subdomain in the [Dashboard](https://app.uploadcare.com/projects/-/settings/#delivery).

### Uploading files

#### Uploading and storing a single file

Using Uploadcare is simple, and here are the basics of handling files.

```ruby
@file_to_upload = File.open("your-file.png")

@uc_file = Uploadcare::Uploader.upload(@file_to_upload, store: "auto")

@uc_file.uuid
# => "dc99200d-9bd6-4b43-bfa9-aa7bfaefca40"

# URL for the file, can be used with your website or app right away
@uc_file.original_file_url
# => "https://demo.ucarecd.net/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/your-file.png"

# CDN URL for the file
@uc_file.cdn_url
# => "https://demo.ucarecd.net/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/"
#
# With subdomains enabled:
# Uploadcare.configuration.use_subdomains = true
# => "https://a1b2c3d4e5.ucarecd.net/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/"
```

The `store` option can have these possible values:

- `true`: mark the uploaded file as stored.
- `false`: do not mark the uploaded file as stored and remove it after 24 hours.
- `"auto"`: defers the choice of storage behavior to the [auto-store setting](https://app.uploadcare.com/projects/-/settings/#storage) for your Uploadcare project. This is the default behavior.

Your might then want to store or delete the uploaded file.

```ruby
# that's how you store a file, if you have uploaded the file using store: false and changed your mind later
@uc_file.store
# => #<Uploadcare::File ...

# and that works for deleting it
@uc_file.delete
# => #<Uploadcare::File ...
```

#### Multiple ways to upload files

Uploadcare supports multiple ways to upload files:

```ruby
# Smart upload - detects type of passed object and picks appropriate upload method
# If you have a large file (more than 100Mb / 10485760 bytes), the uploader will automatically process it with a multipart upload

Uploadcare::Uploader.upload("https://placekitten.com/96/139", store: "auto")
```

There are explicit ways to select upload type:

```ruby
files = [File.open("1.jpg"), File.open("1.jpg")]
Uploadcare::Uploader.upload_files(files, store: 'auto')

Uploadcare::Uploader.upload_from_url("https://placekitten.com/96/139", store: "auto")
```

It is possible to track progress of the upload-from-URL process. To do that, you should specify the `async` option and get a token:

```ruby
Uploadcare::Uploader.upload_from_url("https://placekitten.com/96/139", async: true)
# => "c6e31082-6bdc-4cb3-bef5-14dd10574d72"
```

After the request for uploading-from-URL is sent, you can check the progress of the upload by sending the `get_upload_from_url_status` request:

```ruby
Uploadcare::Uploader.get_upload_from_url_status("1251ee66-3631-4416-a2fb-96ba59f5a515")
# => Success({:size=>453543, :total=>453543, :done=>453543, :uuid=>"5c51a7fe-e45d-42a2-ba5e-79957ff4bdab", :file_id=>"5c51a7fe-e45d-42a2-ba5e-79957ff4bdab", :original_filename=>"2250", :is_image=>true, :is_stored=>false, :image_info=>{:dpi=>[96, 96], :width=>2250, :format=>"JPEG", :height=>2250, :sequence=>false, :color_mode=>"RGB", :orientation=>nil, :geo_location=>nil, :datetime_original=>nil}, :video_info=>nil, :content_info=>{:mime=>{:mime=>"image/jpeg", :type=>"image", :subtype=>"jpeg"}, :image=>{:dpi=>[96, 96], :width=>2250, :format=>"JPEG", :height=>2250, :sequence=>false, :color_mode=>"RGB", :orientation=>nil, :geo_location=>nil, :datetime_original=>nil}}, :is_ready=>true, :filename=>"2250", :mime_type=>"image/jpeg", :metadata=>{}, :status=>"success"})
```

In case of the `async` option is disabled, uploadcare-ruby tries to request the upload status several times (depending on the `max_request_tries` config param) and then returns uploaded file attributes.

#### Direct Upload API Access

For more control over the upload process, you can use the Upload API client directly:

```ruby
# Initialize the upload client
upload_client = Uploadcare::UploadClient.new

# Upload a file directly (supports files up to 100MB)
file = File.open("image.jpg")
response = upload_client.upload_file(file, store: 'auto')

# Response contains file UUID and metadata
puts response['uuid']
# => "dc99200d-9bd6-4b43-bfa9-aa7bfaefca40"

puts response['original_filename']
# => "image.jpg"
```

The `upload_file` method supports the following options:
- **store** - storage behavior: `true`, `false`, or `'auto'` (default)
- **metadata** - custom metadata as a hash (e.g., `{ subsystem: 'avatars', user_id: '123' }`)
- **signature** - upload signature for signed uploads (requires `expire` option)
- **expire** - signature expiration timestamp (Unix timestamp)

Example with metadata:

```ruby
upload_client.upload_file(
  file,
  store: true,
  metadata: {
    subsystem: 'user_uploads',
    category: 'profile_pictures'
  }
)
```

##### Upload from URL

You can upload files from remote URLs using the Upload API:

```ruby
upload_client = Uploadcare::UploadClient.new

# Synchronous upload (waits for completion)
response = upload_client.upload_from_url('https://example.com/image.jpg', store: true)
puts response['uuid']
# => "46e9ed64-1e4d-4c65-887f-1b8679a20a1e"

# Asynchronous upload (returns immediately with a token)
response = upload_client.upload_from_url('https://example.com/image.jpg', async: true)
token = response['token']
# => "b1c4e1dc-e63a-42a4-bb4c-7a25eef2ffdf"

# Check upload status
status = upload_client.upload_from_url_status(token)
case status['status']
when 'success'
  puts "Upload complete: #{status['uuid']}"
when 'progress'
  puts "Upload in progress"
when 'waiting'
  puts "Upload queued"
when 'error'
  puts "Upload failed: #{status['error']}"
end
```

The `upload_from_url` method supports the following options:
- **async** - use async mode (default: `false`)
- **store** - storage behavior: `true`, `false`, or `'auto'`
- **check_URL_duplicates** - check for duplicate URLs: `'0'` or `'1'`
- **save_URL_duplicates** - save URL duplicates: `'0'` or `'1'`
- **metadata** - custom metadata as a hash
- **poll_interval** - polling interval in seconds for sync mode (default: `1`)
- **poll_timeout** - maximum polling time in seconds for sync mode (default: `300`)

##### Multipart Upload

For large files (>10MB), you can use multipart upload which splits the file into chunks and uploads them in parallel:

```ruby
upload_client = Uploadcare::UploadClient.new

# Step 1: Start multipart upload
file = File.open('large_video.mp4', 'rb')
file_size = file.size
filename = File.basename(file.path)
content_type = 'video/mp4'

response = upload_client.multipart_start(filename, file_size, content_type, store: true)
upload_uuid = response['uuid']
presigned_urls = response['parts']

# Step 2: Upload each part
presigned_urls.each_with_index do |presigned_url, index|
  part_size = Uploadcare.configuration.multipart_chunk_size
  file.seek(index * part_size)
  part_data = file.read(part_size)

  break if part_data.nil? || part_data.empty?

  upload_client.multipart_upload_part(presigned_url, part_data)
end

# Step 3: Complete the upload
response = upload_client.multipart_complete(upload_uuid)
puts response['uuid']

file.close
```

**High-Level Multipart Upload (Recommended)**:

For convenience, use the `multipart_upload` method which handles the entire flow automatically:

```ruby
upload_client = Uploadcare::UploadClient.new
file = File.open('large_video.mp4', 'rb')

# Simple upload
response = upload_client.multipart_upload(file, store: true)
puts response['uuid']

# With progress tracking
upload_client.multipart_upload(file, store: true) do |progress|
  percentage = (progress[:uploaded].to_f / progress[:total] * 100).round(2)
  puts "Progress: #{percentage}% (Part #{progress[:part]}/#{progress[:total_parts]})"
end

# With parallel uploads (4 threads)
upload_client.multipart_upload(file, store: true, threads: 4) do |progress|
  puts "Uploaded #{progress[:uploaded]} / #{progress[:total]} bytes"
end

file.close
```

The `multipart_start` method supports the following options:
- **part_size** - size of each part in bytes (default: 5MB)
- **store** - storage behavior: `true`, `false`, or `'auto'`
- **metadata** - custom metadata as a hash

The `multipart_upload_part` method automatically retries failed uploads with exponential backoff:
- **max_retries** - maximum number of retries (default: 3)

The `multipart_upload` method supports:
- **store** - storage behavior
- **metadata** - custom metadata
- **part_size** - size of each part
- **threads** - number of parallel upload threads (default: 1)

```ruby
# multipart upload - can be useful for files bigger than 10 mb
Uploadcare::Uploader.multipart_upload(File.open("big_file.bin"), store: true)
```

For the multipart upload you can pass a block to add some additional logic after each file chunk is uploaded.
For example to track file uploading progress you can do something like this:

```ruby
file = File.open("big_file.bin")
progress = 0
Uploadcare::Uploader.multipart_upload(file, store: true) do |options|
  progress += (100.0 / options[:links_count])
  puts "PROGRESS = #{progress}"
end
```

Output of the code above looks like:

```console
PROGRESS = 4.545454545454546
PROGRESS = 9.090909090909092
PROGRESS = 13.636363636363637
...
```

Options available in a block:

- **:chunk_size** - size of each chunk in bytes;
- **:object** - file object which is going to be uploaded;
- **:offset** - offset from the beginning of a File object in bytes;
- **:link_id** - index of a link provided by Uploadcare API. Might be treated as index of a chunk;
- **:links** - array of links for uploading file's chunks;
- **:links_count** - count of the array of links.

#### Uploading options

You can override [auto-store setting](https://app.uploadcare.com/projects/-/settings/#storage) from your Uploadcare project for each upload request:

```ruby
@api.upload(files, store: true)          # mark the uploaded file as stored.
@api.upload(files, store: false)         # do not mark the uploaded file as stored and remove it after 24 hours.
@api.upload_from_url(url, store: "auto") # defers the choice of storage behavior to the auto-store setting.
```

You can upload file with custom metadata, for example `subsystem` and `pet`:

```ruby
@api.upload(files, metadata: { subsystem: 'my_subsystem', pet: 'cat' } )
@api.upload_from_url(url, metadata: { subsystem: 'my_subsystem', pet: 'cat' })
```

#### Smart Upload with Progress Tracking

The `Uploadcare::Uploader` module provides intelligent upload handling with automatic method selection based on file size and source type:

```ruby
# Upload a small file (< 10MB) - automatically uses base upload
file = File.open('photo.jpg', 'rb')
result = Uploadcare::Uploader.upload(file, store: true)
puts result.uuid
# => "dc99200d-9bd6-4b43-bfa9-aa7bfaefca40"

# Upload a large file (>= 10MB) - automatically uses multipart upload with progress
large_file = File.open('video.mp4', 'rb')
result = Uploadcare::Uploader.upload(large_file, store: true) do |progress|
  puts "Progress: #{progress[:percentage]}% (Part #{progress[:part]}/#{progress[:total_parts]})"
end
puts result.uuid

# Upload from URL - automatically detected
result = Uploadcare::Uploader.upload('https://example.com/image.jpg', store: true)
puts result.uuid

# Batch upload multiple files
files = [
  File.open('photo1.jpg', 'rb'),
  File.open('photo2.jpg', 'rb')
]
results = Uploadcare::Uploader.upload(files, store: true)
results.each { |file| puts file.uuid }
```

The `Uploader.upload` method automatically:
- Detects URLs and uses `upload_from_url`
- Chooses base upload for files < 10MB
- Chooses multipart upload for files >= 10MB
- Handles arrays for batch uploads
- Supports progress callbacks for large files

#### Advanced Upload Options

For more control, you can use the `UploadClient` directly:

```ruby
upload_client = Uploadcare::UploadClient.new

# Upload with custom metadata
file = File.open('document.pdf', 'rb')
response = upload_client.upload_file(file,
  store: true,
  metadata: {
    subsystem: 'documents',
    category: 'invoices',
    user_id: '12345'
  }
)

# Multipart upload with parallel threads and progress
large_file = File.open('large_video.mp4', 'rb')
response = upload_client.multipart_upload(large_file,
  store: true,
  threads: 4,  # Upload 4 parts in parallel
  part_size: 10 * 1024 * 1024  # 10MB chunks
) do |progress|
  uploaded_mb = (progress[:uploaded] / 1024.0 / 1024.0).round(2)
  total_mb = (progress[:total] / 1024.0 / 1024.0).round(2)
  puts "Uploaded #{uploaded_mb}/#{total_mb} MB"
end

# URL upload with custom polling
response = upload_client.upload_from_url(
  'https://example.com/large-file.zip',
  store: true,
  poll_interval: 2,    # Check status every 2 seconds
  poll_timeout: 600    # Wait up to 10 minutes
)

# Async URL upload (returns immediately with token)
response = upload_client.upload_from_url(
  'https://example.com/file.zip',
  async: true
)
token = response['token']

# Check status later
status = upload_client.upload_from_url_status(token)
case status['status']
when 'success'
  puts "Upload complete: #{status['uuid']}"
when 'progress'
  puts "Upload in progress: #{status['done']}/#{status['total']} bytes"
when 'waiting'
  puts "Upload queued"
when 'error'
  puts "Upload failed: #{status['error']}"
end
```

#### Multipart Upload for Large Files

For files >= 10MB, multipart upload is automatically used. You can also use it explicitly:

```ruby
upload_client = Uploadcare::UploadClient.new
file = File.open('large_file.bin', 'rb')

# Simple multipart upload
response = upload_client.multipart_upload(file, store: true)

# With progress tracking
upload_client.multipart_upload(file, store: true) do |progress|
  percentage = (progress[:uploaded].to_f / progress[:total] * 100).round(2)
  puts "Progress: #{percentage}% - Part #{progress[:part]}/#{progress[:total_parts]}"
end

# With parallel uploads (faster for large files)
upload_client.multipart_upload(file,
  store: true,
  threads: 4,  # Upload 4 parts simultaneously
  metadata: { source: 'api', type: 'video' }
) do |progress|
  puts "Uploaded #{progress[:uploaded]} / #{progress[:total]} bytes"
end

file.close
```

**Multipart Upload Options:**
- **store** - storage behavior: `true`, `false`, or `'auto'` (default)
- **metadata** - custom metadata hash
- **part_size** - size of each part in bytes (default: 5MB)
- **threads** - number of parallel upload threads (default: 1, max: 10)

**Progress Callback:**
The progress block receives a hash with:
- **:uploaded** - bytes uploaded so far
- **:total** - total file size in bytes
- **:percentage** - upload percentage (0-100)
- **:part** - current part number
- **:total_parts** - total number of parts

#### Manual Multipart Upload Control

For advanced use cases, you can control each step of the multipart upload:

```ruby
upload_client = Uploadcare::UploadClient.new
file = File.open('large_file.bin', 'rb')

# Step 1: Start multipart upload
response = upload_client.multipart_start(
  File.basename(file.path),
  file.size,
  'application/octet-stream',
  store: true
)
upload_uuid = response['uuid']
presigned_urls = response['parts']

# Step 2: Upload each part
presigned_urls.each_with_index do |url, index|
  part_size = 5 * 1024 * 1024  # 5MB
  file.seek(index * part_size)
  part_data = file.read(part_size)
  break if part_data.nil? || part_data.empty?

  upload_client.multipart_upload_part(url, part_data)
  puts "Uploaded part #{index + 1}/#{presigned_urls.length}"
end

# Step 3: Complete the upload
response = upload_client.multipart_complete(upload_uuid)
puts "Upload complete: #{response['uuid']}"

file.close
```

### File management

The File resource allows you to manage uploaded files, including storing, deleting, copying, and fetching file information.

#### Fetching File Information

```ruby
# Fetch file information with optional inclusion of additional fields (e.g., appdata)
@file = Uploadcare::File.new(uuid: "FILE_UUID")
file_info = @file.info(include: "metadata")
{
  "datetime_removed"=>nil,
  "datetime_stored"=>"2018-11-26T12:49:10.477888Z",
  "datetime_uploaded"=>"2018-11-26T12:49:09.945335Z",
  "is_image"=>true,
  "is_ready"=>true,
  "mime_type"=>"image/jpeg",
  "original_file_url"=>"https://demo.ucarecd.net/FILE_UUID/pineapple.jpg",
  "original_filename"=>"pineapple.jpg",
  "size"=>642,
  "url"=>"https://api.uploadcare.com/files/FILE_UUID/",
  "uuid"=>"FILE_UUID",
  "variations"=>nil,
  "content_info"=>{
    "mime"=>{
      "mime"=>"image/jpeg",
      "type"=>"image",
      "subtype"=>"jpeg"
    },
    "image"=>{
      "format"=>"JPEG",
      "width"=>500,
      "height"=>500,
      "sequence"=>false,
      "orientation"=>6,
      "geo_location"=>{
        "latitude"=>55.62013611111111,
        "longitude"=>37.66299166666666
      },
      "datetime_original"=>"2018-08-20T08:59:50",
      "dpi"=>[72, 72]
    }
  },
  "metadata"=>{
    "subsystem"=>"uploader",
    "pet"=>"cat"
  },
  "appdata"=>{
    "uc_clamav_virus_scan"=>{
      "data"=>{
        "infected"=>true,
        "infected_with"=>"Win.Test.EICAR_HDB-1"
      },
      "version"=>"0.104.2",
      "datetime_created"=>"2021-09-21T11:24:33.159663Z",
      "datetime_updated"=>"2021-09-21T11:24:33.159663Z"
    },
    "remove_bg"=>{
      "data"=>{
        "foreground_type"=>"person"
      },
      "version"=>"1.0",
      "datetime_created"=>"2021-07-25T12:24:33.159663Z",
      "datetime_updated"=>"2021-07-25T12:24:33.159663Z"
    },
    "aws_rekognition_detect_labels"=>{
      "data"=>{
        "LabelModelVersion"=>"2.0",
        "Labels"=>[
          {
            "Confidence"=>93.41645812988281,
            "Instances"=>[],
            "Name"=>"Home Decor",
            "Parents"=>[]
          },
          {
            "Confidence"=>70.75951385498047,
            "Instances"=>[],
            "Name"=>"Linen",
            "Parents"=>[{ "Name"=>"Home Decor" }]
          },
          {
            "Confidence"=>64.7123794555664,
            "Instances"=>[],
            "Name"=>"Sunlight",
            "Parents"=>[]
          },
          {
            "Confidence"=>56.264793395996094,
            "Instances"=>[],
            "Name"=>"Flare",
            "Parents"=>[{ "Name"=>"Light" }]
          },
          {
            "Confidence"=>50.47153854370117,
            "Instances"=>[],
            "Name"=>"Tree",
            "Parents"=>[{ "Name"=>"Plant" }]
          }
        ]
      },
      "version"=>"2016-06-27",
      "datetime_created"=>"2021-09-21T11:25:31.259763Z",
      "datetime_updated"=>"2021-09-21T11:27:33.359763Z"
    }
  }
}

```
#### Storing Files

# Store a single file
``` ruby
file = Uploadcare::File.new(uuid: "FILE_UUID")
stored_file = file.store

puts stored_file.datetime_stored
# => "2024-11-05T09:13:40.543471Z"
```

# Batch store files using their UUIDs
``` ruby
uuids = ['uuid1', 'uuid2', 'uuid3']
batch_result = Uploadcare::File.batch_store(uuids)
```

# Check the status of the operation
``` ruby
puts batch_result.status # => "success"
```

# Access successfully stored files
``` ruby
batch_result.result.each do |file|
  puts file.uuid
end
```

# Handle files that encountered issues
``` ruby
unless batch_result.problems.empty?
  batch_result.problems.each do |uuid, error|
    puts "Failed to store file #{uuid}: #{error}"
  end
end
```

#### Deleting Files

# Delete a single file
```ruby
file = Uploadcare::File.new(uuid: "FILE_UUID")
deleted_file = file.delete
puts deleted_file.datetime_removed
# => "2024-11-05T09:13:40.543471Z"
```

# Batch delete multiple files
```ruby
uuids = ['FILE_UUID_1', 'FILE_UUID_2']
result = Uploadcare::File.batch_delete(uuids)
puts result.result
```

#### Copying Files

# Copy a file to local storage
```ruby
source = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'
file = Uploadcare::File.local_copy(source, store: true)

puts file.uuid
# => "new-uuid-of-the-copied-file"
```

# Copy a file to remote storage
```ruby
source_object = '1bac376c-aa7e-4356-861b-dd2657b5bfd2'
target = 'custom_storage_connected_to_the_project'
file = Uploadcare::File.remote_copy(source_object, target, make_public: true)

puts file
# => "https://my-storage.example.com/path/to/copied-file"
```
The File object also can be converted if it is a document or a video file. Imagine, you have a document file:

```ruby
@file = Uploadcare::File.new(uuid: "FILE_UUID")
```

To convert it to an another file, just do:

```ruby
@converted_file = @file.convert_document({ format: "png", page: "1" }, store: true)
# => {
#    "uuid"=>"<NEW_FILE_UUID>"}
#    ...other file info...
# }
# OR
# Failure({:"<FILE_UUID>/document/-/format/png/-/page/1/"=>"the target_format is not a supported 'to' format for this source file. <you_source_file_extension> -> png"})
```

Same works for video files:

```ruby
@converted_file = @file.convert_video(
  {
    format: "ogg",
    quality: "best",
    cut: { start_time: "0:0:0.1", length: "end" },
    size: { resize_mode: "change_ratio", width: "600", height: "400" },
    thumb: { N: 1, number: 2 }
  },
  store: true
)
# => {
#    "uuid"=>"<NEW_FILE_UUID>"}
#    ...other file info...
# }
# OR
# Failure({:"<FILE_UUID>/video/-/size/600x400/preserve_ratio/-/quality/best/-/format/ogg/-/cut/0:0:0.1/end/-/thumbs~1/2/"=>"CDN Path error: Failed to parse remainder \"/preserve_ratio\" of \"size/600x400/preserve_ratio\""})
```

More about file conversion [here](#conversion).
Metadata of deleted files is stored permanently.

#### FileList

`Uploadcare::File.list` retrieves a collection of files from Uploadcare, supporting optional filtering and pagination. It provides methods to iterate through the collection and access associated file objects seamlessly.

```ruby
# Retrieve a list of files
options = {
  limit: 10,                    # Controls the number of files returned (default: 100)
  stored: true,                 # Only include stored files (optional)
  removed: false,               # Exclude removed files (optional)
  ordering: '-datetime_uploaded', # Order by latest uploaded files first
  from: '2022-01-01T00:00:00'   # Start from this point in the collection
}

@file_list = Uploadcare::File.list(options)
# => Returns an instance of PaginatedCollection containing Uploadcare::File objects
```

This method accepts some options to control which files should be fetched and
how they should be fetched:

- **:limit** — Controls page size. Accepts values from 1 to 1000, defaults to 100.
- **:stored** — Can be either `true` or `false`. When true, file list will contain only stored files. When false — only not stored.
- **:removed** — Can be either `true` or `false`. When true, file list will contain only removed files. When false — all except removed. Defaults to false.
- **:ordering** — Controls the order of returned files. Available values: `datetime_uploaded`, `-datetime_uploaded`. Defaults to `datetime_uploaded`. More info can be found [here](https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/filesList).
- **:from** — Specifies the starting point for a collection. Resulting collection will contain files from the given value and to the end in a direction set by an **ordering** option. When files are ordered by `datetime_updated` in any direction, accepts either a `DateTime` object or an ISO 8601 string. When files are ordered by size, accepts non-negative integers (size in bytes). More info can be found [here](https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/filesList).

Options used to create a file list can be accessed through `#options` method.
Note that, once set, they don't affect file fetching process anymore and are
stored just for your convenience. That is why they are frozen.

```ruby
options = {
  limit: 10,
  stored: true,
  ordering: "-datetime_uploaded",
  from: "2017-01-01T00:00:00",
}
@list = Uploadcare::File.list(options)
```

To simply get all associated objects:

```ruby
@list.all # => returns Array of Files
```

#### Pagination

Initially, `File.list` returns a paginated collection. It can be navigated using following methods:
```ruby
  @file_list = Uploadcare::File.list
  # Let's assume there are 250 files in cloud. By default, UC loads 100 files. To get next 100 files, do:
  @next_page = @file_list.next_page
  # To get previous page:
  @previous_page = @file_list.previous_page
```

Alternatively, it's possible to iterate through full list of groups or files with `each`:

```ruby
@list.each do |file|
  p file.url
end
```

#### Custom File Metadata

File metadata is additional, arbitrary data, associated with uploaded file.
As an example, you could store unique file identifier from your system.

```ruby
# Get file's metadata keys and values.
Uploadcare::FileMetadata.index('FILE_UUID')

# Get the value of a single metadata key.
Uploadcare::FileMetadata.show('FILE_UUID', 'KEY')

# Update the value of a single metadata key. If the key does not exist, it will be created.
Uploadcare::FileMetadata.update('FILE_UUID', 'KEY', 'VALUE')

# Delete a file's metadata key.
Uploadcare::FileMetadata.delete('FILE_UUID', 'KEY')
```

#### Group

Groups are structures intended to organize sets of separate files. Each group is
assigned UUID. Note, group UUIDs include a `~#{files_count}` part at the end.
That's a requirement of our API.

```ruby
# group can be created from an array of Uploadcare files (UUIDs)
@file = "134dc30c-093e-4f48-a5b9-966fe9cb1d01"
@file2 = "134dc30c-093e-4f48-a5b9-966fe9cb1d02"
@files_ary = [@file, @file2]
@group = Uploadcare::Group.create @files

# group can be stored by group ID. It means that all files of a group will be stored on Uploadcare servers permanently
Uploadcare::Group.store(group.id)

# get a file group by its ID.
@group = Uploadcare::Group.new(uuid: "Group UUID")
@group.info("Group UUID")

# group can be deleted by group ID.
@group = Uploadcare::Group.new(uuid: "Group UUID")
@group.delete("Group UUID")
# Note: This operation only removes the group object itself. All the files that were part of the group are left as is.

# Returns group's CDN URL
@group.cdn_url
# => "https://demo.ucarecd.net/group-id~2/"

# Returns CDN URLs of all files from group without API requesting
@group.file_cdn_urls
# => 'https://demo.ucarecd.net/0513dda0-582f-447d-846f-096e5df9e2bb~2/nth/0/'
```

#### GroupList
`Group.list` returns a list of `Group`

```ruby
@group_list = Uploadcare::Group.list
# To get an array of groups:
@groups = @group_list.all
```

This is a paginated list, so [pagination](#Pagination) methods apply

#### Webhook

https://uploadcare.com/docs/api_reference/rest/webhooks/

You can use webhooks to provide notifications about your uploads to target urls.
This gem lets you create and manage webhooks.

Each webhook payload can be signed with a secret (the `signing_secret` option) to ensure that the request comes from the expected sender.
More info about secure webhooks [here](https://uploadcare.com/docs/security/secure-webhooks/).

```ruby
Uploadcare::Webhook.create(target_url: "https://example.com/listen", event: "file.uploaded", is_active: true, signing_secret: "some-secret")
Uploadcare::Webhook.update(<webhook_id>, target_url: "https://newexample.com/listen/new", event: "file.uploaded", is_active: true, signing_secret: "some-secret")
Uploadcare::Webhook.delete("https://example.com/listen")
Uploadcare::Webhook.list
```

##### Webhook signature verification

The gem has a helper class to verify a webhook signature from headers —
`Uploadcare::Param::WebhookSignatureVerifier`. This class accepts three
important options:

- **:webhook_body** — this option represents parameters received in the webhook
  request in the JSON format.
  **NOTE**: if you're using Rails, you should exclude options `controller`,
  `action` and `post` from the `webhook_body`.
- **:signing_secret** — the secret that was set while creating/updating a
  webhook. This option can be specified as an ENV var with the name
  `UC_SIGNING_SECRET` — then no need to send it to the verifier class.
- **:x_uc_signature_header** — the content of the `X-Uc-Signature` HTTP header
  in the webhook request.

Using the `Uploadcare::Param::WebhookSignatureVerifier` class example:

```ruby
  webhook_body = '{...}'

signing_secret = "12345X"
x_uc_signature_header = "v1=9b31c7dd83fdbf4a2e12b19d7f2b9d87d547672a325b9492457292db4f513c70"

Uploadcare::WebhookSignatureVerifier.valid?(signing_secret: signing_secret, x_uc_signature_header: x_uc_signature_header, webhook_body: webhook_body)
```

You can write your verifier. Example code:

```ruby
webhook_body_json = '{...}'

signing_secret = ENV['UC_SIGNING_SECRET']
x_uc_signature_header = "v1=f4d859ed2fe47b9a4fcc81693d34e58ad12366a841e58a7072c1530483689cc0"

digest = OpenSSL::Digest.new('sha256')

calculated_signature = "v1=#{OpenSSL::HMAC.hexdigest(digest, signing_secret.force_encoding("utf-8"), webhook_body_json.force_encoding("utf-8"))}"

if calculated_signature == x_uc_signature_header
  puts "WebHook signature matches!"
else
  puts "WebHook signature mismatch!"
end
```

#### Add-Ons

An `Add-On` is an application implemented by Uploadcare that accepts uploaded files as an input and can produce other files and/or appdata as an output.

##### AWS Rekognition

```ruby
# Execute AWS Rekognition Add-On for a given target to detect labels in an image.
# Note: Detected labels are stored in the file's appdata.
Uploadcare::AddOns.aws_rekognition_detect_labels('FILE_UUID')

# Check the status of AWS Rekognition.
Uploadcare::AddOns.aws_rekognition_detect_labels_status('RETURNED_ID_FROM_WS_REKOGNITION_DETECT_LABELS')
```

##### AWS Rekognition Moderation

```ruby
# Execute AWS Rekognition Moderation Add-On for a given target to detect moderation labels in an image.
# Note: Detected moderation labels are stored in the file's appdata.

Uploadcare::AddOns.aws_rekognition_detect_moderation_labels('FILE_UUID')

# Check the status of an Add-On execution request that had been started using the Execute Add-On operation.
Uploadcare::AddOns.aws_rekognition_detect_moderation_labels_status('RETURNED_ID_FROM_WS_REKOGNITION_DETECT_MODERATION_LABELS')
```

##### ClamAV

```ruby
# ClamAV virus checking Add-On for a given target.
Uploadcare::AddOns.uc_clamav_virus_scan('FILE_UUID')

# Check and purge infected file.
Uploadcare::AddOns.uc_clamav_virus_scan('FILE_UUID', purge_infected: true )

# Check the status of an Add-On execution request that had been started using the Execute Add-On operation.
Uploadcare::AddOns.uc_clamav_virus_scan_status('RETURNED_ID_FROM_UC_CLAMAV_VIRUS_SCAN')
```

##### Remove.bg

```ruby
# Execute remove.bg background image removal Add-On for a given target.
Uploadcare::AddOns.remove_bg('FILE_UUID')

# You can pass optional parameters.
# See the full list of parameters here: https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/removeBgExecute
Uploadcare::AddOns.remove_bg('FILE_UUID', crop: true, type_level: '2')

# Check the status of an Add-On execution request that had been started using the Execute Add-On operation.
Uploadcare::AddOns.remove_bg_status('RETURNED_ID_FROM_REMOVE_BG')
```

#### Project

`show` provides basic info about the connected Uploadcare project. That
object is also an Hashie::Mash, so every methods out of
[these](https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/projectInfo) will work.

```ruby
@project = Uploadcare::Project.show
# => #<Uploadcare::Project collaborators=[], name="demo", pub_key="your_public_key", autostore_enabled=true>

@project.name
# => "demo"

@project.collaborators
# => []
# while that one was empty, it usually goes like this:
# [{"email": collaborator@gmail.com, "name": "Collaborator"}, {"email": collaborator@gmail.com, "name": "Collaborator"}]
```

#### Conversion

##### Video

After each video file upload you obtain a file identifier in UUID format.
Then you can use this file identifier to convert your video in multiple ways:

```ruby
Uploadcare::VideoConverter.convert(
  [
    {
      uuid: "dc99200d-9bd6-4b43-bfa9-aa7bfaefca40",
      size: { resize_mode: "change_ratio", width: "600", height: "400" },
      quality: "best",
      format: "ogg",
      cut: { start_time: "0:0:0.0", length: "0:0:1.0" },
      thumbs: { N: 2, number: 1 }
    }
  ],
  store: false
)
```

This method accepts options to set properties of an output file:

- **uuid** — the file UUID-identifier.
- **size**:
  - **resize_mode** - size operation to apply to a video file. Can be `preserve_ratio (default)`, `change_ratio`, `scale_crop` or `add_padding`.
  - **width** - width for a converted video.
  - **height** - height for a converted video.

```
  NOTE: you can choose to provide a single dimension (width OR height).
        The value you specify for any of the dimensions should be a non-zero integer divisible by 4
```

- **quality** - sets the level of video quality that affects file sizes and hence loading times and volumes of generated traffic. Can be `normal (default)`, `better`, `best`, `lighter`, `lightest`.
- **format** - format for a converted video. Can be `mp4 (default)`, `webm`, `ogg`.
- **cut**:
  - **start_time** - defines the starting point of a fragment to cut based on your input file timeline.
  - **length** - defines the duration of that fragment.
- **thumbs**:
  - **N** - quantity of thumbnails for your video - non-zero integer ranging from 1 to 50; defaults to 1.
  - **number** - zero-based index of a particular thumbnail in a created set, ranging from 1 to (N - 1).
- **store** - a flag indicating if Uploadcare should store your transformed outputs.

```ruby
# Response
{
  :result => [
    {
      :original_source=>"dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/video/-/size/600x400/change_ratio/-/quality/best/-/format/ogg/-/cut/0:0:0.0/0:0:1.0/-/thumbs~2/1/",
      :token=>911933811,
      :uuid=>"6f9b88bd-625c-4d60-bfde-145fa3813d95",
      :thumbnails_group_uuid=>"cf34c5a1-8fcc-4db2-9ec5-62c389e84468~2"
    }
  ],
  :problems=>{}
}
```

Params in the response:

- **result** - info related to your transformed output(-s):
  - **original_source** - built path for a particular video with all the conversion operations and parameters.
  - **token** - a processing job token that can be used to get a [job status](https://uploadcare.com/docs/transformations/video-encoding/#status) (see below).
  - **uuid** - UUID of your processed video file.
  - **thumbnails_group_uuid** - holds :uuid-thumb-group, a UUID of a [file group](https://uploadcare.com/api-refs/rest-api/v0.7.0/#operation/groupsList) with thumbnails for an output video, based on the thumbs [operation](https://uploadcare.com/docs/transformations/video-encoding/#operation-thumbs) parameters.
- **problems** - problems related to your processing job, if any.

To convert multiple videos just add params as a hash for each video to the first argument of the `Uploadcare::VideoConverter#convert` method:

```ruby
Uploadcare::VideoConverter.convert(
  [
    { video_one_params }, { video_two_params }, ...
  ],
  store: false
)
```

To check a status of a video processing job you can simply use appropriate method of `Uploadcare::VideoConverter`:

```ruby
token = 911933811
Uploadcare::VideoConverter.status(token)
```

`token` here is a processing job token, obtained in a response of a convert video request.

```ruby
# Response
{
  :status => "finished",
  :error => nil,
  :result => {
    :uuid => "dc99200d-9bd6-4b43-bfa9-aa7bfaefca40",
    :thumbnails_group_uuid => "0f181f24-7551-42e5-bebc-14b15d9d3838~2"
  }
}
```

Params in the response:

- **status** - processing job status, can have one of the following values:
  - _pending_ — video file is being prepared for conversion.
  - _processing_ — video file processing is in progress.
  - _finished_ — the processing is finished.
  - _failed_ — we failed to process the video, see error for details.
  - _canceled_ — video processing was canceled.
- **error** - holds a processing error if we failed to handle your video.
- **result** - repeats the contents of your processing output.
- **thumbnails_group_uuid** - holds :uuid-thumb-group, a UUID of a file group with thumbnails for an output video, based on the thumbs operation parameters.
- **uuid** - a UUID of your processed video file.

More examples and options can be found [here](https://uploadcare.com/docs/transformations/video-encoding/#video-encoding).

##### Document

After each document file upload you obtain a file identifier in UUID format.

You can use file identifier to determine the document format and possible conversion formats.

```ruby
Uploadcare::DocumentConverter.info("dc99200d-9bd6-4b43-bfa9-aa7bfaefca40")

# Response
{:error=>nil, :format=>{
  :name=>"jpg",
  :conversion_formats=>[
    {:name=>"avif"}, {:name=>"bmp"}, {:name=>"gif"}, {:name=>"ico"}, {:name=>"pcx"}, {:name=>"pdf"}, {:name=>"png"}, {:name=>"ps"}, {:name=>"svg"}, {:name=>"tga"}, {:name=>"thumbnail"}, {:name=>"tiff"}, {:name=>"wbmp"}, {:name=>"webp"}
  ]
}}
```

Then you can use this file identifier to convert your document to a new format:

```ruby
Uploadcare::DocumentConverter.convert(
  [
    {
      uuid: "dc99200d-9bd6-4b43-bfa9-aa7bfaefca40",
      format: "pdf"
    }
  ],
  store: false
)
```

or create an image of a particular page (if using image format):

```ruby
Uploadcare::DocumentConverter.convert(
  [
    {
      uuid: "a4b9db2f-1591-4f4c-8f68-94018924525d",
      format: "png",
      page: 1
    }
  ],
  store: false
)
```

This method accepts options to set properties of an output file:

- **uuid** — the file UUID-identifier.
- **format** - defines the target format you want a source file converted to. The supported values are: `pdf` (default), `doc`, `docx`, `xls`, `xlsx`, `odt`, `ods`, `rtf`, `txt`, `jpg`, `png`. In case the format operation was not found, your input document will be converted to `pdf`.
- **page** - a page number of a multi-paged document to either `jpg` or `png`. The method will not work for any other target formats.

```ruby
# Response
{
  :result => [
    {
      :original_source=>"a4b9db2f-1591-4f4c-8f68-94018924525d/document/-/format/png/-/page/1/",
      :token=>21120220
      :uuid=>"88fe5ada-90f1-422a-a233-3a0f3a7cf23c"
    }
  ],
  :problems=>{}
}
```

Params in the response:

- **result** - info related to your transformed output(-s):
  - **original_source** - source file identifier including a target format, if present.
  - **token** - a processing job token that can be used to get a [job status](https://uploadcare.com/docs/transformations/document-conversion/#status) (see below).
  - **uuid** - UUID of your processed document file.
- **problems** - problems related to your processing job, if any.

To convert multiple documents just add params as a hash for each document to the first argument of the `Uploadcare::DocumentConverter#convert` method:

```ruby
Uploadcare::DocumentConverter.convert(
  [
    { doc_one_params }, { doc_two_params }, ...
  ],
  store: false
)
```

To check a status of a document processing job you can simply use appropriate method of `Uploadcare::DocumentConverter`:

```ruby
token = 21120220
Uploadcare::DocumentConverter.status(token)
```

`token` here is a processing job token, obtained in a response of a convert document request.

```ruby
# Response
{
  :status => "finished",
  :error => nil,
  :result => {
    :uuid => "a4b9db2f-1591-4f4c-8f68-94018924525d"
  }
}
```

Params in the response:

- **status** - processing job status, can have one of the following values:
  - _pending_ — document file is being prepared for conversion.
  - _processing_ — document file processing is in progress.
  - _finished_ — the processing is finished.
  - _failed_ — we failed to process the document, see error for details.
  - _canceled_ — document processing was canceled.
- **error** - holds a processing error if we failed to handle your document.
- **result** - repeats the contents of your processing output.
- **uuid** - a UUID of your processed document file.

More examples and options can be found [here](https://uploadcare.com/docs/transformations/document-conversion/#document-conversion)

## Secure delivery

You can use custom domain and CDN provider to deliver files with authenticated URLs (see [original documentation](https://uploadcare.com/docs/security/secure_delivery/)).

To generate authenticated URL from the library, you should choose `Uploadcare::SignedUrlGenerators::AkamaiGenerator` (or create your own generator implementation):

```ruby
generator = Uploadcare::SignedUrlGenerators::AkamaiGenerator.new(cdn_host: 'example.com', secret_key: 'secret_key')
# Optional parameters: ttl: 300, algorithm: 'sha256'
generator.generate_url(uuid, acl = optional)

generator.generate_url("a7d5645e-5cd7-4046-819f-a6a2933bafe3")
# https://example.com/a7d5645e-5cd7-4046-819f-a6a2933bafe3/?token=exp=1649405263~acl=/a7d5645e-5cd7-4046-819f-a6a2933bafe3/~hmac=a989cae5342f17013677f5a0e6577fc5594cc4e238fb4c95eda36634eb47018b

# You can pass in ACL as a second parameter to generate_url. See https://uploadcare.com/docs/security/secure-delivery/#authenticated-urls for supported acl formats
generator.generate_url("a7d5645e-5cd7-4046-819f-a6a2933bafe3", '/*/')
# https://example.com/a7d5645e-5cd7-4046-819f-a6a2933bafe3/?token=exp=1649405263~acl=/*/~hmac=3ce1152c6af8864b36d4dc721f08ca3cf0b3a20278d7f849e82c6c930d48ccc1

# Optionally you can use wildcard: true to generate a wildcard acl token
generator.generate_url("a7d5645e-5cd7-4046-819f-a6a2933bafe3", wildcard: true)
# https://example.com/a7d5645e-5cd7-4046-819f-a6a2933bafe3/?token=exp=1714233449~acl=/a7d5645e-5cd7-4046-819f-a6a2933bafe3/*~hmac=a568ee2a85dd90a8a8a1ef35ea0cc0ef0acb84fe81990edd3a06eacf10a52b4e

# You can also pass in a custom ttl and algorithm to AkamaiGenerator
generator = Uploadcare::SignedUrlGenerators::AkamaiGenerator.new(cdn_host: 'example.com', secret_key: 'secret_key', ttl: 10)
generator.generate_url("a7d5645e-5cd7-4046-819f-a6a2933bafe3")
# This generates a URL that expires in 10 seconds
# https://example.com/a7d5645e-5cd7-4046-819f-a6a2933bafe3/?token=exp=1714233277~acl=/a7d5645e-5cd7-4046-819f-a6a2933bafe3/~hmac=f25343104aeced3004d2cc4d49807d8d7c732300b54b154c319da5283a871a71
```

## Useful links

- [Development](https://github.com/uploadcare/uploadcare-ruby/blob/main/DEVELOPMENT.md)
- [Uploadcare documentation](https://uploadcare.com/docs/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-ruby)
- [Upload API reference](https://uploadcare.com/api-refs/upload-api/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-ruby)
- [REST API reference](https://uploadcare.com/api-refs/rest-api/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-ruby)
- [Changelog](./CHANGELOG.md)
- [Contributing guide](https://github.com/uploadcare/.github/blob/master/CONTRIBUTING.md)
- [Security policy](https://github.com/uploadcare/uploadcare-ruby/security/policy)
- [Support](https://github.com/uploadcare/.github/blob/master/SUPPORT.md)

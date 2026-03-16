# Uploadcare Ruby SDK

![license](https://img.shields.io/badge/license-MIT-brightgreen.svg)
[![Build Status][actions-img]][actions-badge]
[![Uploadcare stack on StackShare][stack-img]][stack]

[actions-badge]: https://github.com/uploadcare/uploadcare-ruby/actions/workflows/ruby.yml
[actions-img]: https://github.com/uploadcare/uploadcare-ruby/actions/workflows/ruby.yml/badge.svg
[stack-img]: https://img.shields.io/badge/tech-stack-0690fa.svg?style=flat
[stack]: https://stackshare.io/uploadcare/stacks/

`uploadcare-ruby` is a framework-agnostic client for the Uploadcare Upload API and REST API.

The gem is built around:

- explicit `Uploadcare::Client` instances
- client-scoped configuration for multi-account use
- a small convenience layer for common workflows
- full endpoint coverage through `client.api.rest` and `client.api.upload`

- [Requirements](#requirements)
- [Installation](#installation)
- [Design](#design)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Multi-Account Usage](#multi-account-usage)
- [Uploads](#uploads)
- [Files](#files)
- [Groups](#groups)
- [Metadata](#metadata)
- [Webhooks](#webhooks)
- [Add-ons](#add-ons)
- [Conversions](#conversions)
- [Errors and Results](#errors-and-results)
- [Request Options](#request-options)
- [Raw API Access](#raw-api-access)
- [Examples](#examples)
- [Upgrading from v4.x](#upgrading-from-v4x)

## Requirements

- Ruby 3.3+

## Installation

Add the gem to your Gemfile:

```ruby
gem "uploadcare-ruby"
```

Then install:

```bash
bundle
```

Set credentials with environment variables:

```bash
export UPLOADCARE_PUBLIC_KEY=your_public_key
export UPLOADCARE_SECRET_KEY=your_secret_key
```

## Design

The gem has two public layers:

### Convenience layer

This is the default API you should use in applications:

- `client.files`
- `client.groups`
- `client.uploads`
- `client.project`
- `client.webhooks`
- `client.file_metadata`
- `client.addons`
- `client.conversions`

This layer returns resources and collections, and it raises typed exceptions on failure.

### Raw parity layer

This layer mirrors Uploadcare’s REST and Upload APIs:

- `client.api.rest`
- `client.api.upload`

This layer returns `Uploadcare::Result` objects so you can inspect success and failure explicitly.

That split keeps app code clean without losing full API coverage.

## Quick Start

```ruby
require "uploadcare"

client = Uploadcare::Client.new(
  public_key: ENV.fetch("UPLOADCARE_PUBLIC_KEY"),
  secret_key: ENV.fetch("UPLOADCARE_SECRET_KEY")
)

file = File.open("photo.jpg", "rb") do |io|
  client.files.upload(io, store: true)
end

puts file.uuid
puts file.cdn_url
```

You can also configure a default global client:

```ruby
Uploadcare.configure do |config|
  config.public_key = ENV.fetch("UPLOADCARE_PUBLIC_KEY")
  config.secret_key = ENV.fetch("UPLOADCARE_SECRET_KEY")
end

file = File.open("photo.jpg", "rb") do |io|
  Uploadcare.files.upload(io, store: true)
end
```

The recommended style is explicit `Uploadcare::Client` instances. Global configuration is best treated as a default.

## Configuration

Use `Uploadcare.configure` to set process-wide defaults:

```ruby
Uploadcare.configure do |config|
  config.public_key = "public_key"
  config.secret_key = "secret_key"
  config.auth_type = "Uploadcare"
  config.use_subdomains = false
end
```

Or build configuration objects directly:

```ruby
base_config = Uploadcare::Configuration.new(
  public_key: "public_key",
  secret_key: "secret_key"
)

client = Uploadcare::Client.new(config: base_config)
```

Configuration objects are copyable:

```ruby
account_a = Uploadcare::Client.new(config: base_config.with(public_key: "pk-a", secret_key: "sk-a"))
account_b = Uploadcare::Client.new(config: base_config.with(public_key: "pk-b", secret_key: "sk-b"))
```

Common configuration options:

- `public_key`
- `secret_key`
- `auth_type`
- `multipart_size_threshold`
- `multipart_chunk_size`
- `upload_threads`
- `upload_timeout`
- `max_upload_retries`
- `sign_uploads`
- `upload_signature_lifetime`
- `use_subdomains`
- `cdn_base_postfix`
- `default_cdn_base`

CDN helpers:

```ruby
Uploadcare.configure do |config|
  config.use_subdomains = true
  config.cdn_base_postfix = "https://ucarecd.net/"
  config.default_cdn_base = "https://ucarecdn.com/"
end

Uploadcare.configuration.custom_cname
Uploadcare.configuration.cdn_base
```

## Multi-Account Usage

The gem is designed to support multiple Uploadcare projects in the same process:

```ruby
primary = Uploadcare::Client.new(public_key: "pk-1", secret_key: "sk-1")
secondary = Uploadcare::Client.new(public_key: "pk-2", secret_key: "sk-2")

primary_file = primary.files.find(uuid: "uuid-1")
secondary_file = secondary.files.find(uuid: "uuid-2")
```

You can also derive temporary variants from an existing client:

```ruby
admin_client = primary.with(secret_key: "different-secret")
```

Resource objects retain their client context, so subsequent instance operations stay bound to the correct account.

## Uploads

### Smart upload

`client.uploads.upload` accepts:

- an IO or file object
- an array of IO or file objects
- an HTTP or HTTPS URL string

```ruby
file = File.open("photo.jpg", "rb") do |io|
  client.uploads.upload(io, store: true)
end

remote_file = client.uploads.upload("https://example.com/image.jpg", store: true)
```

### Single file upload

```ruby
file = File.open("photo.jpg", "rb") do |io|
  client.files.upload(io, store: true, metadata: { subsystem: "avatars" })
end
```

### Multiple file upload

```ruby
files = [
  File.open("photo-1.jpg", "rb"),
  File.open("photo-2.jpg", "rb")
]

uploaded = client.uploads.upload(files, store: true)

files.each(&:close)
```

### Upload from URL

Synchronous:

```ruby
file = client.files.upload_from_url("https://example.com/image.jpg", store: true)
```

Async:

```ruby
job = client.uploads.upload_from_url(url: "https://example.com/image.jpg", async: true, store: true)
status = client.uploads.upload_from_url_status(token: job.fetch("token"))
```

When async mode is enabled, the convenience layer returns the raw status token hash because the file does not exist yet.

### Multipart upload with progress

```ruby
File.open("large-video.mp4", "rb") do |io|
  file = client.uploads.multipart_upload(file: io, store: true, threads: 4) do |progress|
    uploaded = progress[:uploaded]
    total = progress[:total]
    puts "#{uploaded}/#{total}"
  end

  puts file.uuid
end
```

### Signed uploads

You can enable signed uploads globally:

```ruby
client = Uploadcare::Client.new(
  public_key: "public",
  secret_key: "secret",
  sign_uploads: true
)
```

Or pass explicit signature data per request:

```ruby
File.open("photo.jpg", "rb") do |io|
  client.files.upload(io, signature: "signature", expire: 1_900_000_000)
end
```

### Upload options

Common upload options:

- `store: true | false | "auto"`
- `metadata: { key: value }`
- `signature: "..."`
- `expire: unix_timestamp`
- `async: true` for URL uploads
- `threads:` and `part_size:` for multipart uploads

## Files

### Find a file

```ruby
file = client.files.find(uuid: "file-uuid")
```

### List files

```ruby
files = client.files.list(limit: 100)
files.each { |file| puts file.uuid }
```

List responses are `Uploadcare::Collections::Paginated`:

```ruby
files.next_page
files.previous_page
files.all
```

### Resource operations

```ruby
file.store
file.delete
file.reload
file.reload(params: { include: "appdata" })
```

### Batch operations

```ruby
result = client.files.batch_store(uuids: ["uuid-1", "uuid-2"])

puts result.status
puts result.result.map(&:uuid)
puts result.problems
```

The same shape applies to `client.files.batch_delete`.

### Copy operations

```ruby
copied = client.files.copy_to_local(source: file.uuid, options: { store: true })
remote_url = client.files.copy_to_remote(source: file.uuid, target: "custom_storage")
```

Instance-level variants are also available:

```ruby
copied = file.copy_to_local(options: { store: true })
remote_url = file.copy_to_remote(target: "custom_storage")
```

## Groups

Create a group:

```ruby
group = client.groups.create(uuids: ["uuid-1", "uuid-2"])
```

Find and list groups:

```ruby
group = client.groups.find(group_id: "group-uuid~2")
groups = client.groups.list(limit: 50)
```

Delete a group:

```ruby
group.delete
```

Useful group helpers:

```ruby
group.cdn_url
group.file_cdn_urls
```

## Metadata

```ruby
client.file_metadata.update(uuid: file.uuid, key: "category", value: "avatar")
client.file_metadata.show(uuid: file.uuid, key: "category")
client.file_metadata.index(uuid: file.uuid)
client.file_metadata.delete(uuid: file.uuid, key: "category")
```

`Uploadcare::FileMetadata` is also available as a resource if you need to hold metadata state locally.

## Webhooks

```ruby
webhook = client.webhooks.create(
  target_url: "https://example.com/uploadcare",
  event: "file.uploaded",
  is_active: true
)

client.webhooks.list
client.webhooks.update(id: webhook.id, is_active: false)
client.webhooks.delete(target_url: webhook.target_url)
```

## Add-ons

```ruby
execution = client.addons.aws_rekognition_detect_labels(uuid: file.uuid)
client.addons.aws_rekognition_detect_labels_status(request_id: execution.request_id)

scan = client.addons.uc_clamav_virus_scan(uuid: file.uuid)
client.addons.uc_clamav_virus_scan_status(request_id: scan.request_id)

background = client.addons.remove_bg(uuid: file.uuid)
client.addons.remove_bg_status(request_id: background.request_id)
```

These methods return `Uploadcare::AddonExecution` resources.

## Conversions

Document conversions:

```ruby
info = client.conversions.documents.info(uuid: file.uuid)
job = client.conversions.documents.convert(uuid: file.uuid, format: :pdf)
status = client.conversions.documents.status(token: job.fetch("result").first.fetch("token"))
```

Video conversions:

```ruby
job = client.conversions.videos.convert(uuid: file.uuid, format: :webm, quality: :normal)
status = client.conversions.videos.status(token: job.result.first.fetch("token"))
```

Document conversion `convert` returns the API response hash.

Video conversion `convert` returns a `Uploadcare::VideoConversion` resource.

## Errors and Results

The convenience layer raises exceptions:

- `Uploadcare::Exception::RequestError`
- `Uploadcare::Exception::InvalidRequestError`
- `Uploadcare::Exception::NotFoundError`
- `Uploadcare::Exception::UploadError`
- `Uploadcare::Exception::MultipartUploadError`
- `Uploadcare::Exception::UploadTimeoutError`
- `Uploadcare::Exception::ThrottleError`

Example:

```ruby
begin
  client.files.find(uuid: "missing")
rescue Uploadcare::Exception::NotFoundError => e
  warn e.message
end
```

The raw API layer returns `Uploadcare::Result`:

```ruby
result = client.api.rest.files.info(uuid: "file-uuid")

if result.success?
  puts result.success
else
  warn result.error_message
end
```

## Request Options

Most API calls accept `request_options:` and pass them to the HTTP layer.

Example:

```ruby
client.files.find(uuid: "file-uuid", request_options: { timeout: 10 })
```

Use this when you need per-request timeout control without changing the client’s default configuration.

## Raw API Access

The gem exposes full endpoint-level access through `client.api`.

REST API:

```ruby
client.api.rest.files.list(params: { limit: 10 })
client.api.rest.files.info(uuid: "file-uuid")
client.api.rest.project.show
client.api.rest.webhooks.list
```

Upload API:

```ruby
File.open("photo.jpg", "rb") do |io|
  client.api.upload.files.direct(file: io, store: true)
end

client.api.upload.files.from_url(source_url: "https://example.com/image.jpg", async: true)
client.api.upload.groups.create(files: ["uuid-1", "uuid-2"])
```

Use this layer when you want exact control over the documented endpoints or when you are wrapping the gem from another library.

## Examples

- [api_examples/README.md](./api_examples/README.md): one canonical script per documented REST and Upload API endpoint
- [examples/README.md](./examples/README.md): workflow-oriented demos built on the public client API

Run examples with project-managed Ruby:

```bash
mise exec -- ruby api_examples/rest_api/get_project.rb
mise exec -- ruby examples/simple_upload.rb spec/fixtures/kitten.jpeg
```

## Upgrading from v4.x

See:

- [MIGRATING_V5.md](./MIGRATING_V5.md)
- [api_examples/README.md](./api_examples/README.md)

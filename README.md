# Uploadcare Ruby SDK

![license](https://img.shields.io/badge/license-MIT-brightgreen.svg)
[![Build Status][actions-img]][actions-badge]
[![Uploadcare stack on StackShare][stack-img]][stack]

[actions-badge]: https://github.com/uploadcare/uploadcare-ruby/actions/workflows/ruby.yml
[actions-img]: https://github.com/uploadcare/uploadcare-ruby/actions/workflows/ruby.yml/badge.svg
[stack-img]: https://img.shields.io/badge/tech-stack-0690fa.svg?style=flat
[stack]: https://stackshare.io/uploadcare/stacks/

`uploadcare-ruby` is a framework-agnostic client for the Uploadcare Upload API and REST API.

Version 5 centers the public API around `Uploadcare::Client`, keeps configuration client-scoped, and provides a small convenience layer over canonical endpoint implementations.

- [Requirements](#requirements)
- [Installation](#installation)
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

Use `Uploadcare.configure` for a default configuration:

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

Configuration is copyable:

```ruby
account_a = Uploadcare::Client.new(config: base_config.with(public_key: "pk-a", secret_key: "sk-a"))
account_b = Uploadcare::Client.new(config: base_config.with(public_key: "pk-b", secret_key: "sk-b"))
```

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

Resource objects keep their client context, so instance operations stay bound to the correct account.

## Uploads

### Smart upload

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

```ruby
file = client.files.upload_from_url("https://example.com/image.jpg", store: true)
```

Async URL upload:

```ruby
job = client.uploads.upload_from_url(url: "https://example.com/image.jpg", async: true, store: true)
status = client.uploads.upload_from_url_status(token: job.fetch("token"))
```

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

## Files

Find a file:

```ruby
file = client.files.find(uuid: "file-uuid")
```

List files:

```ruby
files = client.files.list(limit: 100)
files.each { |file| puts file.uuid }
```

Store and delete:

```ruby
file.store
file.delete
```

Reload with includes:

```ruby
file.reload(params: { include: "appdata" })
```

Batch store and delete:

```ruby
client.files.batch_store(uuids: ["uuid-1", "uuid-2"])
client.files.batch_delete(uuids: ["uuid-1", "uuid-2"])
```

Copy operations:

```ruby
copied = client.files.copy_to_local(source: file.uuid, options: { store: true })
remote_url = client.files.copy_to_remote(source: file.uuid, target: "custom_storage")
```

## Groups

Create a group:

```ruby
group = client.groups.create(["uuid-1", "uuid-2"])
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

## Metadata

```ruby
client.file_metadata.update(uuid: file.uuid, key: "category", value: "avatar")
client.file_metadata.show(uuid: file.uuid, key: "category")
client.file_metadata.index(uuid: file.uuid)
client.file_metadata.delete(uuid: file.uuid, key: "category")
```

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

## Raw API Access

The gem exposes full endpoint-level access through `client.api`.

REST API:

```ruby
client.api.rest.files.list(params: { limit: 10 })
client.api.rest.files.info(uuid: "file-uuid")
client.api.rest.project.show
```

Upload API:

```ruby
client.api.upload.files.direct(file: File.open("photo.jpg", "rb"), store: true)
client.api.upload.files.from_url(source_url: "https://example.com/image.jpg", async: true)
client.api.upload.groups.create(files: ["uuid-1", "uuid-2"])
```

## Examples

- [api_examples/README.md](./api_examples/README.md): one canonical script per documented REST and Upload API endpoint
- [examples/README.md](./examples/README.md): workflow-oriented demos built on the public client API

The canonical endpoint examples were verified against a real demo account on `2026-03-16`.

## Upgrading from v4.x

Version 5 is a rewrite with API changes.

- Primary entry point is now `Uploadcare::Client`
- Configuration is intended to be client-scoped
- Public workflow access is centered on `client.files`, `client.groups`, `client.uploads`, `client.webhooks`, `client.file_metadata`, `client.addons`, and `client.conversions`
- Full endpoint coverage is available through `client.api.rest` and `client.api.upload`

See:

- [docs/REWRITE_BLUEPRINT.md](./docs/REWRITE_BLUEPRINT.md)
- [api_examples/README.md](./api_examples/README.md)

# uploadcare-ruby Rewrite Blueprint

## Goal

Rewrite `uploadcare-ruby` into a clean, framework-agnostic core gem with:

- full Uploadcare REST API coverage
- full Uploadcare Upload API coverage
- a small, clear public API
- first-class multi-account support
- explicit internal namespaces
- a thin convenience layer over canonical endpoint implementations

This document is the architecture contract for the rewrite.

## Non-Goals

- no Rails-specific abstractions in this gem
- no Engine or Railtie in this gem
- no attempt to preserve every historical public constant
- no duplicate public pathways for the same operation unless one is clearly low-level and one is clearly convenience

## Design Principles

1. One public entry point.
2. One canonical implementation per API endpoint.
3. Convenience methods compose endpoint methods; they do not duplicate transport logic.
4. Configuration is client-scoped by default.
5. Global configuration exists only as a default template.
6. Internal plumbing stays namespaced and out of the main public surface.
7. Resources represent returned domain objects, not transport machinery.
8. The codebase should be understandable by reading the directory tree.

## Public API

### Primary Usage

```ruby
client = Uploadcare::Client.new(public_key:, secret_key:)

file = client.files.upload(io, store: true)
file = client.files.find(uuid)
files = client.files.list(limit: 100)

group = client.groups.create([uuid1, uuid2])
group = client.groups.find(group_id)

job = client.uploads.from_url(url, async: true)
status = client.uploads.from_url_status(job.token)

project = client.project.current
```

### Global Convenience

```ruby
Uploadcare.configure do |config|
  config.public_key = "pk"
  config.secret_key = "sk"
end

Uploadcare.client
Uploadcare.files
Uploadcare.groups
Uploadcare.uploads
Uploadcare.project
```

### Public Top-Level Constants

These should remain public:

- `Uploadcare::Client`
- `Uploadcare::Configuration`
- `Uploadcare::File`
- `Uploadcare::Group`
- `Uploadcare::Project`
- `Uploadcare::Webhook`
- `Uploadcare::Result` if retained
- `Uploadcare::Exception::*`

Everything else should be treated as internal or semi-internal.

## Configuration Model

### Requirements

- support multiple Uploadcare accounts in the same process
- support multiple clients in the same Rails app
- support per-tenant or per-request clients in `uploadcare-rails`
- avoid hidden global state inside resources

### Rules

- `Uploadcare.configuration` is the default config template
- `Uploadcare.client` returns a client built from the default config
- `Uploadcare::Client.new(...)` owns its own config
- configs must be copyable with overrides
- no class-level client caches keyed by config objects

### Target API

```ruby
base = Uploadcare.configuration
account_a = Uploadcare::Client.new(config: base.with(public_key: "a", secret_key: "x"))
account_b = Uploadcare::Client.new(config: base.with(public_key: "b", secret_key: "y"))
```

### Configuration Responsibilities

- credentials
- API roots
- retry and timeout settings
- signing settings
- CDN settings
- framework identification for user agent

### Configuration Constraints

- environment variables are read at configuration initialization time, not class load time
- configuration values are plain values, not procs
- config object should expose `to_h`
- config object should expose `with(**overrides)`

## Architecture Layers

### 1. Client Layer

`Uploadcare::Client`

Responsibilities:

- own a configuration instance
- expose grouped domain accessors
- expose raw API access

Target shape:

```ruby
client.api
client.files
client.groups
client.uploads
client.project
client.webhooks
client.addons
client.file_metadata
client.conversions
```

### 2. API Parity Layer

Canonical, literal wrappers around Uploadcare endpoints.

Rules:

- method names should closely reflect the docs
- one method per endpoint
- no routing logic
- no transport duplication between convenience and parity layers

Two API roots:

- `Uploadcare::API::REST`
- `Uploadcare::API::Upload`

### 3. Resource Layer

Returned domain objects.

Examples:

- `Uploadcare::Resources::File`
- `Uploadcare::Resources::Group`
- `Uploadcare::Resources::Project`
- `Uploadcare::Resources::Webhook`
- `Uploadcare::Resources::DocumentConversion`
- `Uploadcare::Resources::VideoConversion`

Rules:

- resource objects hold attributes and client context
- instance methods may call the API when intuitive
- resources do not own low-level transport logic

### 4. Collection Layer

Types representing list and batch responses.

Examples:

- `Uploadcare::Collections::Paginated`
- `Uploadcare::Collections::BatchResult`

### 5. Operations Layer

Workflow helpers that compose endpoint methods.

Examples:

- `Uploadcare::Operations::UploadRouter`
- `Uploadcare::Operations::MultipartUpload`

Rules:

- workflow logic lives here
- endpoint classes stay simple
- convenience methods delegate here

### 6. Internal Layer

Low-level HTTP and support code.

Examples:

- `Uploadcare::Internal::HTTPClient`
- `Uploadcare::Internal::Authenticator`
- `Uploadcare::Internal::ErrorHandler`
- `Uploadcare::Internal::ThrottleHandler`
- `Uploadcare::Internal::UserAgent`
- `Uploadcare::Internal::SignatureGenerator`

## Target Directory Structure

```text
lib/uploadcare.rb
lib/uploadcare/client.rb
lib/uploadcare/configuration.rb

lib/uploadcare/api/rest.rb
lib/uploadcare/api/upload.rb

lib/uploadcare/api/rest/files.rb
lib/uploadcare/api/rest/groups.rb
lib/uploadcare/api/rest/project.rb
lib/uploadcare/api/rest/webhooks.rb
lib/uploadcare/api/rest/file_metadata.rb
lib/uploadcare/api/rest/addons.rb
lib/uploadcare/api/rest/document_conversions.rb
lib/uploadcare/api/rest/video_conversions.rb

lib/uploadcare/api/upload/files.rb
lib/uploadcare/api/upload/groups.rb

lib/uploadcare/resources/file.rb
lib/uploadcare/resources/group.rb
lib/uploadcare/resources/project.rb
lib/uploadcare/resources/webhook.rb
lib/uploadcare/resources/document_conversion.rb
lib/uploadcare/resources/video_conversion.rb
lib/uploadcare/resources/addon_execution.rb

lib/uploadcare/collections/paginated.rb
lib/uploadcare/collections/batch_result.rb

lib/uploadcare/operations/upload_router.rb
lib/uploadcare/operations/multipart_upload.rb

lib/uploadcare/internal/http_client.rb
lib/uploadcare/internal/authenticator.rb
lib/uploadcare/internal/error_handler.rb
lib/uploadcare/internal/throttle_handler.rb
lib/uploadcare/internal/user_agent.rb
lib/uploadcare/internal/signature_generator.rb
```

## Endpoint Mapping

### REST API

#### Files

- `list`
- `find`
- `store`
- `delete`
- `batch_store`
- `batch_delete`
- `copy_to_local`
- `copy_to_remote`

#### File Metadata

- `index`
- `show`
- `update`
- `delete`

#### Groups

- `list`
- `find`
- `delete`

#### Project

- `current`

#### Webhooks

- `list`
- `create`
- `update`
- `delete`

#### Add-ons

- `aws_rekognition_detect_labels`
- `aws_rekognition_detect_labels_status`
- `aws_rekognition_detect_moderation_labels`
- `aws_rekognition_detect_moderation_labels_status`
- `uc_clamav_virus_scan`
- `uc_clamav_virus_scan_status`
- `remove_bg`
- `remove_bg_status`

#### Document Conversions

- `info`
- `convert`
- `status`

#### Video Conversions

- `convert`
- `status`

### Upload API

#### Files

- `direct`
- `from_url`
- `from_url_status`
- `info`
- `multipart_start`
- `multipart_part`
- `multipart_complete`

#### Groups

- `create`
- `find`

## Convenience Layer

This layer exists for the happy path and must remain thin.

### Files Domain

```ruby
client.files.upload(io)
client.files.upload_many(files)
client.files.upload_from_url(url)
client.files.find(uuid)
client.files.list(limit: 100)
client.files.copy_to_local(uuid, store: true)
client.files.copy_to_remote(uuid, target: "storage")
```

### Groups Domain

```ruby
client.groups.create([uuid1, uuid2])
client.groups.find(group_id)
client.groups.list(limit: 100)
```

### Project Domain

```ruby
client.project.current
```

### Conversions Domain

```ruby
client.conversions.documents.convert(uuid, format: :pdf)
client.conversions.documents.status(token)
client.conversions.videos.convert(uuid, format: :mp4, quality: :normal)
client.conversions.videos.status(token)
```

## Naming Rules

### Use

- `find`
- `list`
- `create`
- `update`
- `delete`
- `store`
- `copy_to_local`
- `copy_to_remote`
- `upload`
- `upload_many`
- `upload_from_url`
- `current`
- `status`

### Avoid

- `file` as a class method on `File`
- `show` where `find` is clearer
- `UploaderClient` vs `UploadClient` style near-duplicates
- “resource” classes that are actually service objects

## Resource Behavior

### Files

Class methods:

- `.find`
- `.list`
- `.upload`
- `.upload_many`
- `.upload_from_url`
- `.batch_store`
- `.batch_delete`
- `.copy_to_local`
- `.copy_to_remote`

Instance methods:

- `#store`
- `#delete`
- `#reload`
- `#copy_to_local`
- `#copy_to_remote`
- `#convert_to_document`
- `#convert_to_video`
- `#cdn_url`

### Groups

Class methods:

- `.find`
- `.list`
- `.create`

Instance methods:

- `#delete`
- `#reload`
- `#cdn_url`
- `#file_cdn_urls`

## Error Contract

Default public API behavior:

- return values on success
- raise typed exceptions on failure

Typed exceptions should remain under `Uploadcare::Exception`.

If `Result` is retained:

- it should be optional and secondary
- it should not be the main style shown in the README

## Compatibility Policy

### Keep

- `Uploadcare.configure`
- `Uploadcare.configuration`
- `Uploadcare.client`
- top-level `Uploadcare::File`
- top-level `Uploadcare::Group`
- top-level `Uploadcare::Project`
- top-level `Uploadcare::Webhook`

### Remove or Deprecate

- public transport client classes unless explicitly needed
- `Uploader` as a public resource-like abstraction
- duplicate names for the same operation
- legacy aliases that create ambiguity

## Test Strategy

### Unit Tests

- endpoint classes
- resources
- operations
- configuration and client behavior
- multi-account behavior

### Integration Tests

- keep VCR-backed end-to-end coverage for upload and REST workflows
- verify the actual user-facing flows, not just individual method calls

### Required Coverage Areas

- direct upload
- multipart upload
- upload from URL
- file CRUD
- group CRUD
- metadata
- conversions
- add-ons
- webhook management
- multi-account resource behavior

### Compatibility Tests

- only for public APIs explicitly retained

## Implementation Phases

### Phase 1

- finalize public API
- finalize namespaces
- finalize compatibility policy

### Phase 2

- implement new configuration object behavior
- implement `Uploadcare::Client`

### Phase 3

- implement API parity layer
- migrate tests for canonical endpoint methods

### Phase 4

- implement resources and collections

### Phase 5

- implement operations and convenience layer

### Phase 6

- port integration suite
- remove old architecture

### Phase 7

- add compatibility wrappers that survived review
- write migration notes

## Success Criteria

The rewrite is complete when:

- a new user can understand the public API from the README alone
- a maintainer can identify where code belongs from the directory tree
- all endpoints are reachable through one canonical implementation
- multi-account usage is straightforward and explicit
- `uploadcare-rails` can consume `Uploadcare::Client` without depending on internal classes
- the full suite passes with real integration coverage preserved

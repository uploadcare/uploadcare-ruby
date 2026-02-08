# Changelog

## 5.0.0 — 2026-01-06

### ⚠️ BREAKING CHANGES
This is a major rewrite with significant architectural changes. Please review the migration guide below.

### Changed - Architecture Overhaul

#### Dependency Modernization
* **Removed dependencies**:
  * `dry-configurable` — replaced with plain Ruby `Configuration` class
  * `uploadcare-api_struct` — no longer needed with new resource pattern
  * `mimemagic` — replaced with `mime-types`
  * `parallel` — multipart uploads now use native threading
  * `retries` — retry logic now built into clients
* **Added dependencies**:
  * `zeitwerk` (~> 2.6.18) — modern Ruby autoloading
  * `faraday` (~> 2.12) — HTTP client with middleware support
  * `faraday-multipart` (~> 1.0) — multipart upload support
  * `addressable` (~> 2.8) — URI handling and encoding
  * `mime-types` (~> 3.1) — MIME type detection

#### Code Structure
* **Complete rewrite from entity-based to resource-based architecture**
  * Replaced `entity/` classes with simpler `resources/` pattern
  * Restructured client layer from `client/` to `clients/` directory
  * Removed param builders in favor of integrated client logic
  * Changed module structure and namespacing
* **New layered architecture**:
  * `Resources` — public API layer (`Uploadcare::File`, `Uploadcare::Uploader`, etc.)
  * `Clients` — HTTP layer (`FileClient`, `UploaderClient`, `RestClient`, etc.)
  * `Concerns` — shared modules (`ErrorHandler`, `ThrottleHandler`)
* **Simplified require paths**: gemspec now uses single `lib` require path instead of multiple paths
* **Zeitwerk autoloading**: replaces manual `require` statements with automatic module loading

#### Configuration System
* Replaced `Dry::Configurable` with plain Ruby `Configuration` class
* Configuration is now a proper class with documented attributes and YARD annotations
* New configuration options:
  * `multipart_chunk_size` — chunk size for multipart uploads (default: 5MB)
  * `upload_timeout` — upload request timeout in seconds (default: 60)
  * `max_upload_retries` — maximum upload retry attempts (default: 3)

#### HTTP Client
* New `RestClient` class using Faraday with middleware:
  * JSON request/response encoding
  * Automatic error raising on 4xx/5xx responses
  * Built-in throttle handling with exponential backoff
* New `UploadClient` class for Upload API with multipart support
* New `Authenticator` class for HMAC-SHA1 signature generation

### Added - New Features
* **Zeitwerk autoloading** for modern Ruby module management
* **Smart upload detection** with automatic method selection based on file size/type
* **Enhanced multipart upload** with parallel processing support
* **Progress tracking** for all upload operations with real-time callbacks
* **Batch upload capabilities** with error handling per file
* **Thread-safe upload operations** with configurable concurrency
* **New exception classes** for better error handling:
  * `InvalidRequestError` — for 400 Bad Request responses
  * `NotFoundError` — for 404 Not Found responses
  * `UploadError` — for upload-specific failures
  * `RetryError` — for polling/retry scenarios
* **New resource classes**:
  * `BatchFileResult` — for batch store/delete operations
  * `PaginatedCollection` — for paginated API responses
  * `BaseResource` — base class for all resources
* **Comprehensive examples** in `/examples` directory:
  * `simple_upload.rb` — basic file upload
  * `batch_upload.rb` — multiple file uploads
  * `large_file_upload.rb` — multipart upload for large files
  * `upload_with_progress.rb` — progress tracking
  * `url_upload.rb` — upload from URL
  * `group_creation.rb` — file grouping
* **Integration tests** with full end-to-end workflow coverage
* **API examples** in `/api_examples` directory for REST and Upload APIs

### Added - Ruby 4.0 Support
* **Ruby 4.0 Official Support**: Explicitly documented and tested Ruby 4.0.1 compatibility

### Changed - Ruby Version Support
* **Minimum Ruby version**: Now requires Ruby 3.3+ (compatible with Rails main)
* **Supported versions**: Ruby 3.3, 3.4, 4.0
* **Removed support**: Ruby 3.0, 3.1, 3.2 (EOL or nearing EOL)

### Fixed
* JSON response parsing in UploadClient
* Thread safety in parallel uploads with proper error aggregation
* Rubocop configuration to match gemspec Ruby version requirement
* Constant name collision between module and class Uploader
* Proper exponential backoff with jitter in polling logic

### Removed
* Old entity system (`entity/` directory)
* Param builders (`param/` directory) — logic moved into clients
* Legacy concern system (`concern/` directory)
* `Dry::Configurable` dependency and DSL
* `uploadcare-api_struct` dependency
* Support for Ruby < 3.3

### Migration Guide from v4.x to v5.0

#### Module Changes
```ruby
# Old (v4.x)
Uploadcare::Entity::File
Uploadcare::Client::FileClient

# New (v5.0)
Uploadcare::File
Uploadcare::FileClient
```

#### Upload API Changes
```ruby
# Old (v4.x)
Uploadcare::Uploader.upload_from_url(url)

# New (v5.0) - Smart detection
Uploadcare::Uploader.upload(url)  # Automatically detects URL
Uploadcare::Uploader.upload(file) # Automatically uses multipart for large files
```

#### Configuration Changes
```ruby
# Old (v4.x) - Dry::Configurable DSL
Uploadcare.configure do |config|
  config.public_key = 'your_public_key'
  config.secret_key = 'your_secret_key'
end

# New (v5.0) - Plain Ruby Configuration class (same syntax, different implementation)
Uploadcare.configure do |config|
  config.public_key = 'your_public_key'
  config.secret_key = 'your_secret_key'
  # New options available:
  config.upload_timeout = 120
  config.max_upload_retries = 5
  config.multipart_chunk_size = 10 * 1024 * 1024  # 10MB chunks
end
```

#### Error Handling Changes
```ruby
# Old (v4.x)
rescue Uploadcare::Exception::RequestError => e

# New (v5.0) - More specific exceptions available
rescue Uploadcare::Exception::NotFoundError => e
  # Handle 404 specifically
rescue Uploadcare::Exception::InvalidRequestError => e
  # Handle 400 specifically
rescue Uploadcare::Exception::RequestError => e
  # Handle other errors
```

#### Batch Operations
```ruby
# New in v5.0 - BatchFileResult for batch operations
result = Uploadcare::File.batch_store(uuids)
result.status    # => 200
result.result    # => Array of File objects
result.problems  # => Hash of UUIDs that failed with reasons
```

## 4.5.0 — 2025-07-25
### Added
* **CDN Subdomain Support**: Added support for automatic subdomain generation to improve CDN performance and caching.
  * New `CnameGenerator` class for generating CNAME prefixes based on public key using SHA256 hashing
  * Configuration options:
    * `use_subdomains` - Enable automatic subdomain generation (default: `false`)
    * `cdn_base_postfix` - Base domain for subdomain generation (default: `https://ucarecd.net/`)
    * `default_cdn_base` - Original CDN base URL (default: `https://ucarecdn.com/`)
    * `cdn_base` - Dynamic CDN base selection based on subdomain configuration
  * New `cdn_url` method for `File` and `Group` entities to get CDN URLs using configured base
  * New `file_cdn_urls` method for `Group` entities to get CDN URLs of all files in a group without API requests
* New `Uploadcare::Exception::ConfigurationError` for configuration-related errors
* Ruby 3.4 support added to test matrix

## 4.4.3 — 2024-07-06

### Added
* Multi page conversion parameter (`save_in_group`) added to `DocumentConverter#convert` options.

### Fixed
* Fixed that signed URLs now work with ~ in the path. This also fixes signed URLs with grouped file URLs.

## 4.4.2 — 2024-05-29

### Fixed
* Fixed the `Uploadcare::File.remote_copy` method which raised an `ApiStruct::EntityError: {url} must be Hash`. Now returns a string instead of a `File` entity instance.

### Added
* `Document Info` API added in `DocumentConverter`.

## 4.4.1 — 2024-04-27

### Added
* Added `AWS Rekognition Moderation` Add-On.
* Added an optional `wildcard` boolean parameter to the `generate_url` method of `AkamaiGenerator`.

### Changed
* File attribute `datetime_stored` is deprecated and will warn on usage from `File` object properties.

### Fixed

* Throw `AuthError` if current public key or secret key config are empty when accessing any of the APIs.
* `AmakaiGenerator` has been renamed to `AkamaiGenerator` to fix typo in class name.

## 4.4.0 — 2024-03-09

### Breaking

* Drop support of unmaintainable Ruby versions < 3.x.

### Fixed

* Update locations where Dry::Monads structure has changed.
* Sign URL uploads if configured (#139).
* Start returning proper error message when raising RequestError in poll_upload_response, to hint to users what is going on. Fixes #141.
* When polling, raise if an error is returned (#142).
* Fix documentation about original file url on simple file upload.

### Changed
* Support params in Rest client and in file info method, to allow passing custom params like "include=appdata" in `Uploadcare::File.file` calls. Closes #132.


## 4.3.6 — 2023-11-18

### Fixed

* Updated the version of the REST Api for conversion clients (closes #135).

## 4.3.5 — 2023-09-19

### Changed

* Updated behavior to exclude sending blank values in the `store` param.


## 4.3.4 — 2023-05-16

### Changed

* Use `auto` as the default value for the `store` param.


## 4.3.3 — 2023-04-14

### Changed

* Use `file_info` request after a file upload if the secret key is not provided.

### Added

* Add a new `file_info` method to retreive file information without the secret key.

## 4.3.2 — 2023-03-28

### Changed

* Improved readme to look better at ruby-doc

## 4.3.1 — 2023-03-17

### Changed

- Update the gem description
- Allow ENV keys to be configured after the gem load

## 4.3.0 — 2023-03-15

Add support of new ruby versions

### Breaking Сhanges

- Drop support of unmaintainable Ruby versions (2.4, 2.5, 2.6).
- Replace unmaintainable `api_struct` with `uploadcare-api_struct`

### Added

- Add support for Ruby 3+ (3.0, 3.1, 3.2).

## 4.0.0 — 2022-12-29

This version supports latest Uploadcare REST API — [v0.7](https://uploadcare.com/api-refs/rest-api/v0.7.0/), which introduces new file management features:
* [File metadata](https://uploadcare.com/docs/file-metadata/)
* New [add-ons API](https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons):
  * [Background removal](https://uploadcare.com/docs/remove-bg/)
  * [Virus checking](https://uploadcare.com/docs/security/malware-protection/)
  * [Object recognition](https://uploadcare.com/docs/intelligence/object-recognition/)

### Breaking Сhanges

- For `Uploadcare::File#info`
  - File information doesn't return `image_info` and `video_info` fields anymore
  - Removed `rekognition_info` in favor of `appdata`
  - Parameter `add_fields` was renamed to `include`
- For `Uploadcare::FileList#file_list`
  - Removed the option of sorting the file list by file size
- For `Uploadcare::Group#store`
  - Changed response format
- For `Uploadcare::File`
  - Removed method `copy` in favor of `local_copy` and `remote_copy` methods

### Changed

- For `Uploadcare::File#info`
  - Field `content_info` that includes mime-type, image (dimensions, format, etc), video information (duration, format, bitrate, etc), audio information, etc
  - Field `metadata` that includes arbitrary metadata associated with a file
  - Field `appdata` that includes dictionary of application names and data associated with these applications

### Added

- Add Uploadcare API interface:
    - `Uploadcare::FileMetadata`
    - `Uploadcare::Addons`
- Added an option to delete a Group
- For `Uploadcare::File` add `local_copy` and `remote_copy` methods

## 3.3.2 - 2022-07-18

- Fixes dry-configurable deprecation warnings

## 3.3.1 - 2022-04-19

- Fixed README: `Uploadcare::URLGenerators::AmakaiGenerator` > `Uploadcare::SignedUrlGenerators::AmakaiGenerator`
- Autoload generators constants

## 3.3.0 — 2022-04-08

- Added `Uploadcare::URLGenerators::AmakaiGenerator`. Use custom domain and CDN provider to deliver files with authenticated URLs

## 3.2.0 — 2021-11-16

- Added option `signing_secret` to the `Uploadcare::Webhook`
- Added webhook signature verifier class `Uploadcare::Param::WebhookSignatureVerifier`

## 3.1.1 — 2021-10-13

- Fixed `Uploadcare::File#store`
- Fixed `Uploadcare::File#delete`

## 3.1.0 — 2021-09-21

- Added documents and videos conversions
- Added new attributes to the Entity class (`variations`, `video_info`, `source`, `rekognition_info`)
- Added an option to add custom logic to large files uploading process

## 3.0.5 — 2021-04-15

- Replace Travis-CI with Github Actions
- Automate gem pushing

## 3.0.4-dev — 2020-03-19

- Added better pagination methods for `GroupList` & `FileList`
- Improved documentation and install instructions
- Added CI

## 3.0.3-dev — 2020-03-13

- Added better pagination and iterators for `GroupList` & `FileList`

## 3.0.2-dev — 2020-03-11

- Expanded `File` and `Group` entities
- Changed user agent syntax

## 3.0.1-dev — 2020-03-11

- Added Upload/group functionality
- Added user API
- Added user agent
- Isolated clients, entities and concerns
- Expanded documentation

## 3.0.0-dev — 2020-02-18

### Changed

- Rewrote gem from scratch

### Added

- Client wrappers for REST API
- Serializers for REST API
- Client wrappers for Upload API
- Serializers for Upload API
- rdoc documentation

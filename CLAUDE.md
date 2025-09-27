# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Uploadcare Ruby SDK - Ruby client library for Uploadcare's Upload and REST APIs, providing file upload, management, and transformation capabilities.

## Development Commands

### Environment Setup
- Ruby 3.0+ required (use mise for version management: `mise use ruby@latest`)
- Install dependencies: `bundle install`
- Add `gem 'base64'` to Gemfile if using Ruby 3.4+ to avoid vcr gem warnings

### Testing
- Run all tests: `bundle exec rake spec` or `bundle exec rspec`
- Run specific test file: `bundle exec rspec spec/uploadcare/resources/file_spec.rb`
- Run with documentation format: `bundle exec rspec --format documentation`
- Run with fail-fast: `bundle exec rspec --fail-fast`
- Test environment variables required:
  - `UPLOADCARE_PUBLIC_KEY=demopublickey`
  - `UPLOADCARE_SECRET_KEY=demoprivatekey`

### Code Quality
- Run linter: `bundle exec rubocop`
- Run linter with auto-fix: `bundle exec rubocop -a`
- Run all checks (tests + linter): `bundle exec rake`

## Architecture Overview

### Core Module Structure
The gem uses Zeitwerk autoloading with collapsed directories for resources and clients:

- **lib/uploadcare.rb** - Main module, configures Zeitwerk autoloading
- **lib/uploadcare/configuration.rb** - Configuration management
- **lib/uploadcare/api.rb** - Main API interface (deprecated pattern, use resources directly)
- **lib/uploadcare/client.rb** - New client pattern for API interactions

### Resource Layer (lib/uploadcare/resources/)
Domain objects representing Uploadcare entities:
- **file.rb** - File upload/management operations
- **group.rb** - File group operations
- **webhook.rb** - Webhook management
- **uploader.rb** - Upload coordination
- **paginated_collection.rb** - Pagination support for list operations
- **batch_file_result.rb** - Batch operation results
- **add_ons.rb** - Add-on services (AWS Rekognition, ClamAV, Remove.bg)
- **document_converter.rb** - Document conversion operations
- **video_converter.rb** - Video conversion operations

### Client Layer (lib/uploadcare/clients/)
HTTP client implementations for API communication:
- **rest_client.rb** - Base REST API client
- **upload_client.rb** - Upload API client
- **multipart_upload_client.rb** - Multipart upload handling
- **uploader_client.rb** - Upload coordination client
- **file_client.rb** - File management endpoints
- **group_client.rb** - Group management endpoints
- **webhook_client.rb** - Webhook endpoints
- **project_client.rb** - Project info endpoints

### Middleware Layer (lib/uploadcare/middleware/)
Request/response processing:
- **base.rb** - Base middleware class
- **retry.rb** - Retry logic for failed requests
- **logger.rb** - Request/response logging

### Error Handling
- **lib/uploadcare/error_handler.rb** - Central error parsing and handling
- **lib/uploadcare/exception/** - Custom exception types
  - **request_error.rb** - Base request errors
  - **auth_error.rb** - Authentication errors
  - **throttle_error.rb** - Rate limiting errors
  - **retry_error.rb** - Retry exhaustion errors

### Utilities
- **lib/uploadcare/authenticator.rb** - Request signing and authentication
- **lib/uploadcare/url_builder.rb** - CDN URL generation with transformations
- **lib/uploadcare/signed_url_generators/** - Secure URL generation (Akamai)
- **lib/uploadcare/throttle_handler.rb** - Rate limit handling

## Key Design Patterns

1. **Resource-Client Separation**: Resources handle business logic, clients handle HTTP communication
2. **Zeitwerk Autoloading**: Uses collapsed directories for cleaner require structure
3. **Middleware Pattern**: Extensible request/response processing pipeline
4. **Result Objects**: Many operations return Success/Failure result objects
5. **Lazy Loading**: Paginated collections fetch data on demand

## API Configuration

Configuration can be set via:
- Environment variables: `UPLOADCARE_PUBLIC_KEY`, `UPLOADCARE_SECRET_KEY`
- Code: `Uploadcare.config.public_key = "key"`
- Per-request: Pass config to individual resource methods

## Testing Approach

- Uses RSpec for testing
- VCR for recording/replaying HTTP interactions
- SimpleCov for code coverage reporting
- Tests are in `spec/uploadcare/` mirroring lib structure
- Fixtures and cassettes in `spec/fixtures/`

## Common Development Tasks

### Adding New API Endpoints
1. Create/update client in `lib/uploadcare/clients/`
2. Create/update resource in `lib/uploadcare/resources/`
3. Add corresponding specs in `spec/uploadcare/`
4. Update README.md with usage examples

### Handling API Responses
- Use `Uploadcare::ErrorHandler` for error parsing
- Return result objects for operations that can fail
- Parse JSON responses into Ruby objects/hashes

### Working with Batch Operations
- Use `BatchFileResult` for batch store/delete results
- Handle both successful results and problem items
- Follow pattern in `File.batch_store` and `File.batch_delete`
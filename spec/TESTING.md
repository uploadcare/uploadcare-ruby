# Testing Guide

This document describes the testing approaches used in the uploadcare-ruby gem and when to use each.

## Overview

The test suite uses two complementary approaches for mocking HTTP requests:

1. **WebMock** — For unit tests with explicit request/response stubs
2. **VCR** — For integration tests that record and replay real API interactions

## When to Use Each Approach

### Use WebMock (`stub_request`) for:

- **Unit tests** — Testing individual methods in isolation
- **Client specs** — Testing HTTP client behavior with controlled responses
- **Error handling** — Testing specific error scenarios (400, 404, 500, etc.)
- **Edge cases** — Testing unusual response formats or error conditions
- **Fast, deterministic tests** — When you need predictable, instant responses

```ruby
# Example: spec/uploadcare/api/rest/files_spec.rb
describe '#store' do
  before do
    stub_request(:put, "#{rest_api_root}/files/#{uuid}/storage/")
      .to_return(
        status: 200,
        body: response_body.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  it { is_expected.to include('uuid' => uuid) }
end
```

**Advantages:**
- Explicit control over request matching and responses
- No external dependencies or cassette files
- Easy to test error scenarios
- Tests run quickly

### Use VCR (`VCR.use_cassette`) for:

- **Integration tests** — Testing complete workflows end-to-end
- **Upload operations** — Testing actual file upload flows
- **Complex multi-step operations** — When multiple API calls are involved
- **Verifying real API behavior** — When you need to ensure compatibility with the actual API

```ruby
# Example: spec/uploadcare/integration_spec.rb
it 'performs the full lifecycle' do
  VCR.use_cassette('file_lifecycle') do
    file = client.files.find(uuid: uuid)
    expect(file).to be_kind_of(Uploadcare::File)
  end
end
```

**Advantages:**
- Records real API responses for accurate testing
- Captures complex multi-request flows automatically
- Ensures tests match actual API behavior
- Good for regression testing

### Use RSpec Mocks (`allow_any_instance_of`) for:

- **Resource specs** — Testing resource classes that delegate to clients
- **Behavior verification** — When you care about method calls, not HTTP details
- **Isolation** — When testing higher-level abstractions

```ruby
# Example: spec/uploadcare/resources/file_spec.rb
before do
  allow(client.api.rest.files).to receive(:info)
    .with(uuid: uuid, request_options: {})
    .and_return(Uploadcare::Result.success(response_body))
end
```

## Directory Structure

```
spec/
├── fixtures/
│   └── vcr_cassettes/           # VCR recorded cassettes
│       └── Upload_API_Integration/  # Integration test cassettes
├── integration/
│   └── upload_spec.rb           # End-to-end integration tests (uses VCR)
├── support/
│   └── vcr.rb                   # VCR configuration
└── uploadcare/
    ├── api/                     # API endpoint specs (use WebMock)
    ├── client_spec.rb           # Client/accessor specs
    ├── operations/              # Workflow helpers
    └── resources/               # Resource specs (use RSpec mocks)
```

## VCR Configuration

VCR is configured in `spec/support/vcr.rb`:

```ruby
VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.filter_sensitive_data('<uploadcare_public_key>') { Uploadcare.configuration.public_key }
  config.filter_sensitive_data('<uploadcare_secret_key>') { Uploadcare.configuration.secret_key }
  config.configure_rspec_metadata!
end
```

### Recording New Cassettes

To record a new cassette:

1. Ensure you have valid API credentials in `.env` or environment variables
2. Delete the existing cassette file (if updating)
3. Run the spec — VCR will record the real API interaction
4. Commit the new cassette file

### Using VCR Metadata

For integration specs, you can use the `:vcr` metadata tag:

```ruby
it 'uploads and retrieves file', :vcr do
  # VCR automatically creates cassette from spec description
end
```

## Best Practices

1. **Prefer WebMock for unit tests** — Faster, more explicit, easier to maintain
2. **Use VCR for integration tests** — Captures real API behavior
3. **Keep cassettes minimal** — Only record what's needed for the test
4. **Filter sensitive data** — Never commit real API keys in cassettes
5. **Update cassettes periodically** — API responses may change over time
6. **Name cassettes descriptively** — Use names that indicate what's being tested

## Running Tests

```bash
# Run all tests
mise exec -- bundle exec rspec

# Run only unit tests (fast)
mise exec -- bundle exec rspec spec/uploadcare/

# Run integration tests
mise exec -- bundle exec rspec spec/integration/

# Run with verbose output
mise exec -- bundle exec rspec --format documentation
```

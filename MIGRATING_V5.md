# Migrating From v4.x to v5

Version 5 moves the gem to a client-first API with a clearer split between the convenience layer and the endpoint-parity API.

The main migration rule is simple:

- use `Uploadcare::Client` for application code
- use `client.files`, `client.groups`, `client.uploads`, and the other domain accessors for normal workflows
- use `client.api.rest` and `client.api.upload` when you need exact Uploadcare endpoint behavior

## What Changed

Version 5 introduces:

- a client-scoped configuration model
- first-class multi-account support
- a convenience layer that returns resources and raises typed exceptions
- a raw API layer that mirrors the REST and Upload APIs and returns `Uploadcare::Result`
- a modernized internal structure built around Zeitwerk and Faraday

Version 5 also raises the minimum supported Ruby version to `3.3`.
The CI matrix for v5 verifies `3.3`, `3.4`, and `4.0`.

If you run examples locally with `.env`, use it only for developer machines and never commit real keys.
The examples expect `UPLOADCARE_PUBLIC_KEY` and `UPLOADCARE_SECRET_KEY` to come from environment variables.

## Recommended Migration Order

1. Introduce explicit `Uploadcare::Client` instances in your application.
2. Move app-facing code to `client.files`, `client.groups`, `client.uploads`, `client.project`, `client.webhooks`, `client.file_metadata`, `client.addons`, and `client.conversions`.
3. Keep `client.api.rest` and `client.api.upload` only where you need raw endpoint parity.
4. Audit return-type and error-handling assumptions.
5. Remove any app code that depends on internal transport classes.

## Configuration

### Before

Typical v4 code relied more heavily on the process-wide configuration singleton.

```ruby
Uploadcare.configure do |config|
  config.public_key = ENV.fetch("UPLOADCARE_PUBLIC_KEY")
  config.secret_key = ENV.fetch("UPLOADCARE_SECRET_KEY")
end
```

### After

Global configuration still exists, but the preferred style is explicit clients.

```ruby
client = Uploadcare::Client.new(
  public_key: ENV.fetch("UPLOADCARE_PUBLIC_KEY"),
  secret_key: ENV.fetch("UPLOADCARE_SECRET_KEY")
)
```

You can also build and copy configuration objects directly:

```ruby
base = Uploadcare::Configuration.new(
  public_key: ENV.fetch("UPLOADCARE_PUBLIC_KEY"),
  secret_key: ENV.fetch("UPLOADCARE_SECRET_KEY")
)

primary = Uploadcare::Client.new(config: base)
secondary = Uploadcare::Client.new(
  config: base.with(public_key: "other-public-key", secret_key: "other-secret-key")
)
```

This is the intended approach for multi-tenant Rails apps and for integrations that need more than one Uploadcare project in one process.

## Public API Mapping

### Uploads

```ruby
# v4-ish
Uploadcare::Uploader.upload(object: file, store: true)

# v5
client.files.upload(file, store: true)
# or
client.uploads.upload(file, store: true)
```

```ruby
# v4-ish
Uploadcare::Uploader.upload(object: url, store: true)

# v5
client.files.upload_from_url(url, store: true)
```

```ruby
# v4-ish
Uploadcare::Uploader.upload_from_url(url: url, async: true)

# v5
client.uploads.upload_from_url(url: url, async: true)
```

```ruby
# v4-ish
Uploadcare::Uploader.upload_from_url_status(token: token)

# v5
client.uploads.upload_from_url_status(token: token)
```

### Files

```ruby
# v4-ish
Uploadcare::File.info(uuid: uuid)

# v5
client.files.find(uuid: uuid)
```

```ruby
# v4-ish
Uploadcare::File.list(options: { limit: 100 })

# v5
client.files.list(limit: 100)
```

```ruby
# v4-ish
Uploadcare::File.batch_store(uuids: uuids)

# v5
client.files.batch_store(uuids: uuids)
```

```ruby
# v4-ish
Uploadcare::File.batch_delete(uuids: uuids)

# v5
client.files.batch_delete(uuids: uuids)
```

### Groups

```ruby
# v4-ish
Uploadcare::Group.create(uuids: uuids)

# v5
client.groups.create(uuids: uuids)
```

```ruby
# v4-ish
Uploadcare::Group.info(group_id: group_id)

# v5
client.groups.find(group_id: group_id)
```

### Metadata

```ruby
# v4-ish
Uploadcare::FileMetadata.update(uuid: uuid, key: "key", value: "value")

# v5
client.file_metadata.update(uuid: uuid, key: "key", value: "value")
```

### Webhooks

```ruby
# v4-ish
Uploadcare::Webhook.create(target_url: url)

# v5
client.webhooks.create(target_url: url)
```

### Add-ons

```ruby
# v4-ish
Uploadcare::Addons.check_remove_bg_status(request_id: request_id)

# v5
client.addons.remove_bg_status(request_id: request_id)
```

## Top-Level Constants

These top-level resource constants still exist:

- `Uploadcare::File`
- `Uploadcare::Group`
- `Uploadcare::Project`
- `Uploadcare::Webhook`
- `Uploadcare::FileMetadata`
- `Uploadcare::DocumentConversion`
- `Uploadcare::VideoConversion`

They remain useful for compatibility and for direct resource-oriented usage, but the main application entry point is now `Uploadcare::Client`.

## Errors and Results

### Convenience Layer

The convenience layer unwraps results and raises typed exceptions.

```ruby
file = client.files.find(uuid: uuid)
```

Typical exceptions include:

- `Uploadcare::Exception::RequestError`
- `Uploadcare::Exception::InvalidRequestError`
- `Uploadcare::Exception::NotFoundError`
- `Uploadcare::Exception::UploadError`
- `Uploadcare::Exception::MultipartUploadError`
- `Uploadcare::Exception::UploadTimeoutError`
- `Uploadcare::Exception::ThrottleError`

### Raw API Layer

The raw API layer returns `Uploadcare::Result`.

```ruby
result = client.api.rest.files.info(uuid: uuid)

if result.success?
  puts result.success
else
  warn result.error_message
end
```

If your v4 code assumed direct hashes everywhere, decide explicitly whether it belongs on the convenience layer or the raw API layer.

## Return Type Changes

### Files and Groups

Convenience methods now return resource objects and paginated collections:

- `client.files.find` -> `Uploadcare::File`
- `client.files.list` -> `Uploadcare::Collections::Paginated`
- `client.groups.find` -> `Uploadcare::Group`

### Batch Operations

Batch operations return `Uploadcare::Collections::BatchResult`.

```ruby
result = client.files.batch_store(uuids: uuids)

result.status
result.result
result.problems
```

### Conversions

Document and video conversions are intentionally not perfectly symmetrical:

- `client.conversions.documents.convert` returns the API response hash
- `client.conversions.videos.convert` returns a `Uploadcare::VideoConversion` resource

Audit conversion code carefully if you rely on exact return types.

## Internal APIs

Version 5 keeps the internal transport layer available and documented, but it is not the recommended primary surface for application code.

If you need it:

- `client.api.rest`
- `client.api.upload`

If you are wrapping the gem from another library, prefer these explicit raw API entry points over reaching into lower-level internals.

## See Also

- [README.md](./README.md)
- [CHANGELOG.md](./CHANGELOG.md)

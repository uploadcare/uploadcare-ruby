# Migrating From v4.x to v5.0

Version 5 is a rewrite. The main change is architectural: application code should now be written against `Uploadcare::Client` and its domain accessors instead of a mix of global helpers and transport-oriented classes.

## Core Shift

### v4 style

The old API encouraged a flatter surface with more global access:

- entity-style objects
- transport-specific client classes in application code
- older upload helpers and naming

### v5 style

The new API is organized around:

- `Uploadcare::Client`
- `client.files`
- `client.groups`
- `client.uploads`
- `client.project`
- `client.webhooks`
- `client.file_metadata`
- `client.addons`
- `client.conversions`
- `client.api.rest` and `client.api.upload` for endpoint-level access

## What To Change First

1. Create explicit clients instead of relying on implicit global state.
2. Move application code to the convenience layer (`client.files`, `client.groups`, and so on).
3. Use `client.api.*` only where you need exact endpoint parity.
4. Stop depending on internal transport classes as part of your app-facing API.

## Configuration

### Before

Configuration was more framework-shaped and less client-oriented.

### After

Configuration is a plain Ruby object and every client owns its own config.

```ruby
base = Uploadcare::Configuration.new(
  public_key: ENV.fetch("UPLOADCARE_PUBLIC_KEY"),
  secret_key: ENV.fetch("UPLOADCARE_SECRET_KEY")
)

client = Uploadcare::Client.new(config: base)
other = Uploadcare::Client.new(config: base.with(public_key: "other", secret_key: "secret"))
```

Global configuration still exists:

```ruby
Uploadcare.configure do |config|
  config.public_key = ENV.fetch("UPLOADCARE_PUBLIC_KEY")
  config.secret_key = ENV.fetch("UPLOADCARE_SECRET_KEY")
end
```

But the recommended approach for applications, especially multi-tenant apps, is explicit clients.

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
client.groups.create(uuids)
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

## Namespace Changes

The public top-level resource constants remain:

- `Uploadcare::File`
- `Uploadcare::Group`
- `Uploadcare::Project`
- `Uploadcare::Webhook`
- `Uploadcare::FileMetadata`
- `Uploadcare::DocumentConversion`
- `Uploadcare::VideoConversion`

But the main entry point for application code is now `Uploadcare::Client`.

Internal transport and implementation classes are no longer the recommended public surface.

## Result and Error Handling

This is one of the most important behavioral changes.

### Convenience layer

The convenience layer unwraps results and raises exceptions:

```ruby
file = client.files.find(uuid: uuid)
```

If the request fails, you get a typed exception.

### Raw API layer

The raw API layer returns `Uploadcare::Result`:

```ruby
result = client.api.rest.files.info(uuid: uuid)

if result.success?
  puts result.success
else
  warn result.error_message
end
```

If your v4 code expected direct hashes everywhere, be explicit about whether you want the convenience layer or the raw parity layer.

## Return Type Changes

### Files and groups

Convenience methods return resources and collections:

- `client.files.find` -> `Uploadcare::File`
- `client.files.list` -> `Uploadcare::Collections::Paginated`
- `client.groups.find` -> `Uploadcare::Group`

### Batch operations

Batch operations return `Uploadcare::Collections::BatchResult`:

```ruby
result = client.files.batch_store(uuids: uuids)

result.status
result.result
result.problems
```

### Conversions

Document and video conversions are not perfectly symmetrical:

- `client.conversions.documents.convert` returns the API response hash
- `client.conversions.videos.convert` returns a `Uploadcare::VideoConversion` resource

If you are migrating conversion code, verify the return type you rely on.

## Exceptions

Version 5 exposes more specific exception types, including:

- `Uploadcare::Exception::RequestError`
- `Uploadcare::Exception::InvalidRequestError`
- `Uploadcare::Exception::NotFoundError`
- `Uploadcare::Exception::UploadError`
- `Uploadcare::Exception::MultipartUploadError`
- `Uploadcare::Exception::UploadTimeoutError`
- `Uploadcare::Exception::ThrottleError`

## Recommended Migration Strategy

1. Introduce `Uploadcare::Client` and pass it explicitly where possible.
2. Move upload code to `client.files` / `client.uploads`.
3. Move file, group, metadata, and webhook code to client accessors.
4. Replace any direct reliance on internal transport classes with `client.api`.
5. Audit return-type assumptions, especially for conversions and batch operations.
6. Add tests around multi-account behavior if your app uses more than one Uploadcare project.

## See Also

- [README.md](./README.md)
- [api_examples/README.md](./api_examples/README.md)
- [CHANGELOG.md](./CHANGELOG.md)

# Migrating From v4.x to v5.0

Version 5.0 is a major rewrite with architectural changes. Review these updates before upgrading.

## Breaking Changes Summary

### Dependencies Changed
- Removed: `dry-configurable`, `uploadcare-api_struct`, `mimemagic`, `parallel`, `retries`
- Added: `zeitwerk`, `faraday`, `faraday-multipart`, `addressable`, `mime-types`

### Ruby Version
- Minimum Ruby version is now 3.3+.
- Supported versions: Ruby 3.3, 3.4, 4.0.

### Module/Class Namespace Changes

```ruby
# Old (v4.x)
Uploadcare::Entity::File
Uploadcare::Client::FileClient

# New (v5.0)
Uploadcare::File
Uploadcare::FileClient
```

### Configuration
Configuration moved from `Dry::Configurable` to a plain Ruby configuration class.

```ruby
Uploadcare.configure do |config|
  config.public_key = 'your_public_key'
  config.secret_key = 'your_secret_key'
  config.upload_timeout = 120
  config.max_upload_retries = 5
  config.multipart_chunk_size = 10 * 1024 * 1024
end
```

### Method Renames

| Old Method (v4.x) | New Method (v5.0) |
|-------------------|-------------------|
| `Addons.check_aws_rekognition_detect_labels_status` | `Addons.aws_rekognition_detect_labels_status` |
| `Addons.check_aws_rekognition_detect_moderation_labels_status` | `Addons.aws_rekognition_detect_moderation_labels_status` |
| `Addons.check_uc_clamav_virus_scan_status` | `Addons.uc_clamav_virus_scan_status` |
| `Addons.check_remove_bg_status` | `Addons.remove_bg_status` |

### Smart Upload Detection
`Uploadcare::Uploader.upload` now auto-detects input type and chooses the upload method.

```ruby
Uploadcare::Uploader.upload(object: 'https://example.com/image.jpg')
Uploadcare::Uploader.upload(object: large_file)
Uploadcare::Uploader.upload(object: [file1, file2, file3])
```

### New Exception Classes
More specific exception classes are available:
- `Uploadcare::Exception::NotFoundError`
- `Uploadcare::Exception::InvalidRequestError`
- `Uploadcare::Exception::UploadError`
- `Uploadcare::Exception::RetryError`
- `Uploadcare::Exception::RequestError`

### Batch Operations Return Type
Batch operations now return `Uploadcare::BatchFileResult`.

```ruby
result = Uploadcare::File.batch_store(uuids: uuids)
result.status
result.result
result.problems
```

### Thread Safety
- Upload operations are thread-safe.
- Multipart uploads use native Ruby threads.

## See Also
- [README](./README.md)
- [CHANGELOG](./CHANGELOG.md)

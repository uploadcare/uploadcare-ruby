# Uploadcare Ruby SDK - Upload API Examples

This directory contains practical examples demonstrating how to use the Uploadcare Upload API with the Ruby SDK.

## Prerequisites

1. Install the gem:
```bash
gem install uploadcare-ruby
```

2. Set your API keys:
```bash
export UPLOADCARE_PUBLIC_KEY=your_public_key
export UPLOADCARE_SECRET_KEY=your_secret_key
```

Or create a `.env` file:
```env
UPLOADCARE_PUBLIC_KEY=your_public_key
UPLOADCARE_SECRET_KEY=your_secret_key
```

## Examples

### 1. Simple Upload (`simple_upload.rb`)
Basic file upload example showing the simplest way to upload a file.

```bash
ruby examples/simple_upload.rb path/to/file.jpg
```

**Features demonstrated:**
- Basic file upload
- Automatic method detection
- File storage

### 2. Upload with Progress (`upload_with_progress.rb`)
Upload large files with real-time progress tracking.

```bash
ruby examples/upload_with_progress.rb path/to/large_file.mp4
```

**Features demonstrated:**
- Large file upload (multipart)
- Progress callbacks
- Progress bar display
- Speed and ETA calculation

### 3. Batch Upload (`batch_upload.rb`)
Upload multiple files at once.

```bash
ruby examples/batch_upload.rb file1.jpg file2.jpg file3.jpg
```

**Features demonstrated:**
- Multiple file upload
- Parallel processing
- Error handling per file
- Summary reporting

### 4. Large File Upload (`large_file_upload.rb`)
Detailed example of multipart upload for files >= 10MB.

```bash
ruby examples/large_file_upload.rb path/to/large_file.bin
```

**Features demonstrated:**
- Multipart upload
- Parallel part uploads
- Progress tracking
- Configurable chunk size

### 5. URL Upload (`url_upload.rb`)
Upload files from remote URLs.

```bash
ruby examples/url_upload.rb https://example.com/image.jpg
```

**Features demonstrated:**
- URL upload
- Async and sync modes
- Status polling
- Error handling

### 6. Group Creation (`group_creation.rb`)
Create file groups from uploaded files.

```bash
ruby examples/group_creation.rb file1.jpg file2.jpg file3.jpg
```

**Features demonstrated:**
- File upload
- Group creation
- Group information retrieval
- CDN URL generation

## Common Patterns

### Error Handling
All examples include proper error handling:

```ruby
begin
  result = Uploadcare::Uploader.upload(object: file, store: true)
  puts "Success: #{result.uuid}"
rescue StandardError => e
  puts "Error: #{e.message}"
end
```

### Progress Tracking
For large files, use progress callbacks:

```ruby
Uploadcare::Uploader.upload(object: file, store: true) do |progress|
  percentage = progress[:percentage]
  puts "Progress: #{percentage}%"
end
```

### Metadata
Add custom metadata to uploads:

```ruby
Uploadcare::Uploader.upload(object: file,
  store: true,
  metadata: {
    category: 'photos',
    user_id: '12345'
  }
)
```

## API Documentation

For complete API documentation, see:
- [Upload API Reference](https://uploadcare.com/api-refs/upload-api/)
- [Main README](../README.md)

## Support

- [Documentation](https://uploadcare.com/docs/)
- [GitHub Issues](https://github.com/uploadcare/uploadcare-ruby/issues)
- [Community Forum](https://community.uploadcare.com/)

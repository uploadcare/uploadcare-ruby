# Workflow Examples

This directory contains higher-level workflow demos built on the public client API.

For endpoint-by-endpoint coverage, use [api_examples/README.md](../api_examples/README.md).

## Setup

```bash
export UPLOADCARE_PUBLIC_KEY=your_public_key
export UPLOADCARE_SECRET_KEY=your_secret_key
```

Run scripts with project-managed Ruby:

```bash
mise exec -- ruby examples/simple_upload.rb spec/fixtures/kitten.jpeg
```

## Scripts

- `examples/simple_upload.rb`
  Upload one file and print its UUID and CDN URL.
- `examples/upload_with_progress.rb`
  Upload one large file with multipart progress reporting.
- `examples/batch_upload.rb`
  Upload multiple files in one call.
- `examples/large_file_upload.rb`
  Force multipart upload and show throughput details.
- `examples/url_upload.rb`
  Upload a remote URL and show async polling as a follow-up example.
- `examples/group_creation.rb`
  Upload multiple files, create a group, and print group details.

## Notes

- These are workflow demos.
- The canonical API inventory lives in `api_examples/`.
- The examples assume real Uploadcare credentials and network access.

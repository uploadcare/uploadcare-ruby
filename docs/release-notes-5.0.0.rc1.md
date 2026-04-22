# uploadcare-ruby 5.0.0.rc1

This release candidate is the first public v5 cut from the rewritten codebase.

Please review [MIGRATING_V5.md](../MIGRATING_V5.md) before upgrading from v4.x.

## Highlights

- New client-first public API centered on `Uploadcare::Client`
- Full endpoint-parity access through `client.api.rest` and `client.api.upload`
- Multi-account support through client-scoped `Uploadcare::Configuration`
- Faraday + Zeitwerk modernization across the codebase
- Ruby 4.0 support in the CI matrix

## Important Fixes Included In RC1

- REST signing uses deterministic protocol-required digests (`MD5` and `SHA1`)
- REST query signing uses the same nested parameter encoding as request transmission
- Multipart upload retries/timeouts now honor configuration (`max_upload_retries`, `upload_timeout`)
- Multipart upload worker cancellation now stops remaining queued work after first worker error
- Upload-from-URL polling now supports exponential backoff with configurable cap
- Multipart start payload no longer sends unsupported `part_size` to `/multipart/start/`
- Upload API batch uploads avoid duplicate filename key collisions without mutating caller-visible filenames
- `FileMetadata` resource instance initialization correctly assigns `uuid`

## Upgrade Notes

- Ruby support baseline is now `>= 3.3`.
- If you use multiple Uploadcare projects/accounts, prefer explicit `Uploadcare::Client` instances.
- Keep rollback simple by pinning to the latest v4 release if your app depends on removed internal APIs.

## Full Changelog

See [CHANGELOG.md](../CHANGELOG.md).

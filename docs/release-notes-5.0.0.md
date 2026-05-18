# uploadcare-ruby 5.0.0

v5 is stable.
No API changes since `5.0.0.rc1`.
What to do now: run the full test suite in staging, validate large multipart uploads, deploy, and monitor for 24-72 hours.

Please review [MIGRATING_V5.md](../MIGRATING_V5.md) before upgrading from v4.x.

## Highlights

- Use `Uploadcare::Client` as the primary API; avoid internal helpers.
- Use `client.api.rest` and `client.api.upload` when you need exact endpoint behavior.
- Create one client per project for multi-account setups.
- Faraday and Zeitwerk reduce internal coupling; audit code that relied on old internals.
- Follow the canonical API examples, workflow examples, migration docs, and Context7 rules for v5.
- CI covers Ruby 3.3, 3.4, and 4.0.

## Important Fixes Included

- REST signing uses deterministic protocol-required digests (`MD5` and `SHA1`)
- REST query signing uses the same nested parameter encoding as request transmission
- Multipart upload retries/timeouts now honor configuration (`max_upload_retries`, `upload_timeout`)
- Multipart upload worker cancellation now stops remaining queued work after first worker error
- Upload-from-URL polling now supports exponential backoff with configurable cap
- Multipart start payload no longer sends unsupported `part_size` to `/multipart/start/`
- Upload API batch uploads avoid duplicate filename key collisions without mutating caller-visible filenames
- `FileMetadata` resource instance initialization correctly assigns `uuid`

## Upgrade Notes

- Requirement: Ruby `>= 3.3`.
- Do this first: run the full test suite against v5 in staging.
- Example check: `bundle update uploadcare-ruby && bundle exec rspec`.
- Multi-account apps: create one `Uploadcare::Client` per project.
- Audit code for removed internal APIs; replace them with `client.files`, `client.groups`, `client.uploads`, or `client.api`.
- Test large-file uploads because multipart retry and cancellation behavior changed.
- Re-validate custom REST signing if your app reimplements signing outside this gem.
- Rollback: pin to the latest v4 release and keep rollback trivial.

## Risk Notes

- v5 uses Faraday and Zeitwerk with simpler internal dependencies; audit any app code that relied on old internals.
- Post-deploy: monitor upload errors, multipart worker failures, and REST signing errors for 24-72 hours.

## Full Changelog

See [CHANGELOG.md](../CHANGELOG.md).

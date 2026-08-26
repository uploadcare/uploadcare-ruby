# uploadcare-ruby 5.1.0

This release adds file search and file-tag support to the v5 client API. It is backward compatible with 5.0.x and
does not require an application migration.

## Highlights

- Search files through `client.files.search` using text, UUID, metadata, tag, range, and image filters.
- Sort search results, inspect match highlights, request `appdata`, and paginate without rebuilding POST criteria.
- List, replace, add, and delete per-file tags through `client.file_tags`.
- Assign tags during direct, batch, URL, and multipart uploads.
- Read tags directly from returned file resources.
- Use `client.api.rest.files.search` and `client.api.rest.file_tags` for exact REST endpoint access.

## Upgrade Notes

- Requirement: Ruby `>= 3.3`.
- Update with `bundle update uploadcare-ruby` and run the application's test suite.
- No configuration or data migration is required from 5.0.x.
- File search results may be eventually consistent immediately after an upload; retry when a workflow searches for a
  file it just created.
- Existing upload calls remain valid. Pass `tags: [...]` only where upload-time tagging is needed.
- Rollback: pin `uploadcare-ruby` to `5.0.1`.

## Examples

- File search: [`examples/file_search.rb`](../examples/file_search.rb)
- File tags: [`examples/file_tags.rb`](../examples/file_tags.rb)
- Raw REST examples: [`api_examples/README.md`](../api_examples/README.md)

## Full Changelog

See [CHANGELOG.md](../CHANGELOG.md).

# Changelog

### 2.1.0, FIXME

- Allow user to override User-Agent header
- Change User-Agent format to report gem name, version and environment

### 2.0.0, 26.09.2017

- There are **breaking** changes in this release, please read [upgrade notes](UPGRADE_NOTES.md#v1---v2)
- Added support for `store` flag in [Upload API](https://uploadcare.com/documentation/upload/) methods
- Upgraded to REST API v0.5
- All POST/PUT/DELETE params are now being sent as JSON instead of being form-encoded
- Added methods to store/delete multiple files at once: `Uploadcare::Api#store_files` & `Uploadcare::Api#delete_files`
- Changed pagination implementation for files and groups

### 1.1.0, 21.03.2017

- Deprecated `Uploadcare::Api::File#copy` in favor of `#internal_copy` and `#external_copy`.
- Added to new methods to `Uploadcare::Api::File`, `#internal_copy` and `#external_copy`.
- Added support of [secure authorization](https://uploadcare.com/documentation/rest/#request) for REST API. It is now used by default (can be overriden in config)
- Fixed middleware names that could break other gems ([#13](https://github.com/uploadcare/uploadcare-ruby/issues/13)).


### 1.0.6, 30.01.2017

- Fixed incorrect dependencies
- Added ruby version and public API key to User-Agent header (can be overriden in config)

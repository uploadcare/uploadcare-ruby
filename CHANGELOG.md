#Changelog

### 1.1.0

- Deprecated `Uploadcare::Api::File#copy` in favor of `#internal_copy` and `#external_copy`.
- Added to new methods to Uploadcare::Api::File, #internal_copy and #external_copy.
- Added support of [secure authorization](https://uploadcare.com/documentation/rest/#request) for REST API. It is now used by default (can be overriden in config)
- Fixed middleware names that could break other gems ([#13](https://github.com/uploadcare/uploadcare-ruby/issues/13}).

### 1.0.6, 30.01.2017

- Fixed incorrect dependencies
- Added ruby version and public API key to User-Agent header (can be overriden in config)

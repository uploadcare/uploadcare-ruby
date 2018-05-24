# Changelog
All notable changes to this project will be documented in this file.

The format is based now on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).


### [1.2.1] - 2018-05-24

### Changed
- Allow user to override User-Agent header
- User-Agent format reports gem name, version and environment


## 1.1.0 - 2017-03-21

### Added
- Added to new methods to `Uploadcare::Api::File`, `#internal_copy` and `#external_copy`.
- Added support of [secure authorization](https://uploadcare.com/documentation/rest/#request) for REST API. It is now used by default (can be overriden in config)

### Fixed
- Fixed middleware names that could break other gems ([#13](https://github.com/uploadcare/uploadcare-ruby/issues/13)).

### Deprecated
- `Uploadcare::Api::File#copy` in favor of `#internal_copy` and `#external_copy`.


## 1.0.6 - 2017-01-30

### Added
- Ruby version and public API key sent via User-Agent header (can be overriden in config)

### Fixed
- Incorrect dependencies


[1.2.1]: https://github.com/uploadcare/uploadcare-ruby/compare/6dde...v1.2.1

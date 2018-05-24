# Changelog
All notable changes to this project will be documented in this file.

The format is based now on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased] - FIXME


## [2.1.1] - 2018-05-24

### Changed
- Allow user to override User-Agent header
- User-Agent format reports gem name, version and environment

## 2.1.0 - 2018-04-23 [YANKED]

## 2.0.0 - 2017-09-26

There are **breaking** changes in this release, please read [upgrade notes](UPGRADE_NOTES.md#v1---v2)

### Added
- Support for `store` flag in [Upload API](https://uploadcare.com/documentation/upload/) methods
- Methods to store/delete multiple files at once: `Uploadcare::Api#store_files` & `Uploadcare::Api#delete_files`

### Changed
- Upgraded to REST API v0.5
- All POST/PUT/DELETE params are now being sent as JSON instead of being form-encoded
- Pagination implementation for files and groups

## 1.1.0 - 2017-03-21

### Added
- Added to new methods to `Uploadcare::Api::File`, `#internal_copy` and `#external_copy`.
- Added support of [secure authorization](https://uploadcare.com/documentation/rest/#request) for REST API. It is now used by default (can be overriden in config)

### Fixed
- Fixed middleware names that could break other gems ([#13](https://github.com/uploadcare/uploadcare-ruby/issues/13)).

### Deprecated
- `Uploadcare::Api::File#copy` in favor of `#internal_copy` and `#external_copy`.


## 1.0.6, 2017-01-30

### Added
- Ruby version and public API key sent via User-Agent header (can be overriden in config)

### Fixed
- Incorrect dependencies


[Unreleased]: https://github.com/uploadcare/uploadcare-ruby/compare/v2.1.1...HEAD
[2.1.1]: https://github.com/uploadcare/uploadcare-ruby/compare/v2.0.0...v2.1.1
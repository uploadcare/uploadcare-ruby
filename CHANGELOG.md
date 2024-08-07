# Changelog

## 4.4.3 — 2024-07-06

### Added
* Multi page conversion parameter (`save_in_group`) added to `DocumentConverter#convert` options.

### Fixed
* Fixed that signed URLs now work with ~ in the path. This also fixes signed URLs with grouped file URLs. 

## 4.4.2 — 2024-05-29

### Fixed
* Fixed the `Uploadcare::File.remote_copy` method which raised an `ApiStruct::EntityError: {url} must be Hash`. Now returns a string instead of a `File` entity instance.

### Added
* `Document Info` API added in `DocumentConverter`.

## 4.4.1 — 2024-04-27

### Added
* Added `AWS Rekognition Moderation` Add-On.
* Added an optional `wildcard` boolean parameter to the `generate_url` method of `AkamaiGenerator`.

### Changed
* File attribute `datetime_stored` is deprecated and will warn on usage from `File` object properties.

### Fixed

* Throw `AuthError` if current public key or secret key config are empty when accessing any of the APIs.
* `AmakaiGenerator` has been renamed to `AkamaiGenerator` to fix typo in class name.

## 4.4.0 — 2024-03-09

### Breaking

* Drop support of unmaintainable Ruby versions < 3.x.

### Fixed

* Update locations where Dry::Monads structure has changed.
* Sign URL uploads if configured (#139).
* Start returning proper error message when raising RequestError in poll_upload_response, to hint to users what is going on. Fixes #141.
* When polling, raise if an error is returned (#142).
* Fix documentation about original file url on simple file upload.

### Changed
* Support params in Rest client and in file info method, to allow passing custom params like "include=appdata" in `Uploadcare::File.file` calls. Closes #132.


## 4.3.6 — 2023-11-18

### Fixed

* Updated the version of the REST Api for conversion clients (closes #135).

## 4.3.5 — 2023-09-19

### Changed

* Updated behavior to exclude sending blank values in the `store` param.


## 4.3.4 — 2023-05-16

### Changed

* Use `auto` as the default value for the `store` param.


## 4.3.3 — 2023-04-14

### Changed

* Use `file_info` request after a file upload if the secret key is not provided.

### Added

* Add a new `file_info` method to retreive file information without the secret key.

## 4.3.2 — 2023-03-28

### Changed

* Improved readme to look better at ruby-doc

## 4.3.1 — 2023-03-17

### Changed

- Update the gem description
- Allow ENV keys to be configured after the gem load

## 4.3.0 — 2023-03-15

Add support of new ruby versions

### Breaking Сhanges

- Drop support of unmaintainable Ruby versions (2.4, 2.5, 2.6).
- Replace unmaintainable `api_struct` with `uploadcare-api_struct`

### Added

- Add support for Ruby 3+ (3.0, 3.1, 3.2).

## 4.0.0 — 2022-12-29

This version supports latest Uploadcare REST API — [v0.7](https://uploadcare.com/api-refs/rest-api/v0.7.0/), which introduces new file management features:
* [File metadata](https://uploadcare.com/docs/file-metadata/)
* New [add-ons API](https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons):
  * [Background removal](https://uploadcare.com/docs/remove-bg/)
  * [Virus checking](https://uploadcare.com/docs/security/malware-protection/)
  * [Object recognition](https://uploadcare.com/docs/intelligence/object-recognition/)

### Breaking Сhanges

- For `Uploadcare::File#info`
  - File information doesn't return `image_info` and `video_info` fields anymore
  - Removed `rekognition_info` in favor of `appdata`
  - Parameter `add_fields` was renamed to `include`
- For `Uploadcare::FileList#file_list`
  - Removed the option of sorting the file list by file size
- For `Uploadcare::Group#store`
  - Changed response format
- For `Uploadcare::File`
  - Removed method `copy` in favor of `local_copy` and `remote_copy` methods

### Changed

- For `Uploadcare::File#info`
  - Field `content_info` that includes mime-type, image (dimensions, format, etc), video information (duration, format, bitrate, etc), audio information, etc
  - Field `metadata` that includes arbitrary metadata associated with a file
  - Field `appdata` that includes dictionary of application names and data associated with these applications

### Added

- Add Uploadcare API interface:
    - `Uploadcare::FileMetadata`
    - `Uploadcare::Addons`
- Added an option to delete a Group
- For `Uploadcare::File` add `local_copy` and `remote_copy` methods

## 3.3.2 - 2022-07-18

- Fixes dry-configurable deprecation warnings

## 3.3.1 - 2022-04-19

- Fixed README: `Uploadcare::URLGenerators::AmakaiGenerator` > `Uploadcare::SignedUrlGenerators::AmakaiGenerator`
- Autoload generators constants

## 3.3.0 — 2022-04-08

- Added `Uploadcare::URLGenerators::AmakaiGenerator`. Use custom domain and CDN provider to deliver files with authenticated URLs

## 3.2.0 — 2021-11-16

- Added option `signing_secret` to the `Uploadcare::Webhook`
- Added webhook signature verifier class `Uploadcare::Param::WebhookSignatureVerifier`

## 3.1.1 — 2021-10-13

- Fixed `Uploadcare::File#store`
- Fixed `Uploadcare::File#delete`

## 3.1.0 — 2021-09-21

- Added documents and videos conversions
- Added new attributes to the Entity class (`variations`, `video_info`, `source`, `rekognition_info`)
- Added an option to add custom logic to large files uploading process

## 3.0.5 — 2021-04-15

- Replace Travis-CI with Github Actions
- Automate gem pushing

## 3.0.4-dev — 2020-03-19

- Added better pagination methods for `GroupList` & `FileList`
- Improved documentation and install instructions
- Added CI

## 3.0.3-dev — 2020-03-13

- Added better pagination and iterators for `GroupList` & `FileList`

## 3.0.2-dev — 2020-03-11

- Expanded `File` and `Group` entities
- Changed user agent syntax

## 3.0.1-dev — 2020-03-11

- Added Upload/group functionality
- Added user API
- Added user agent
- Isolated clients, entities and concerns
- Expanded documentation

## 3.0.0-dev — 2020-02-18

### Changed

- Rewrote gem from scratch

### Added

- Client wrappers for REST API
- Serializers for REST API
- Client wrappers for Upload API
- Serializers for Upload API
- rdoc documentation

# Changelog

## 4.0.0

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

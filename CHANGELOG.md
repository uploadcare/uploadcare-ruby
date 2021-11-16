# Changelog

## 3.1.2 2021-11-16

- Add option "signing_secret" to webhooks

## 3.1.1 2021-10-13

- Fix Uploadcare::File#store
- Fix Uploadcare::File#delete

## 3.1.0 2021-09-21

- Added documents and videos conversion
- Added new attributes to the Entity class (variations, video_info, source, rekognition_info)
- Added an opportunity to add custom logic to large files uploading process

## 3.0.5 2021-04-15

- Replace Travis-CI with Github Actions
- Automate gem pushing

## 3.0.4-dev 2020-03-19

- Added better pagination methods for GroupList & FileList
- Improved documentation and install instructions
- Added CI

## 3.0.3-dev 2020-03-13
- Added better pagination and iterators for GroupList & FileList

## 3.0.2-dev 2020-03-11

- Expanded File and Group entities
- Changed user agent syntax

## 3.0.1-dev 2020-03-11

- Added Upload/group functionality
- Added user API
- Added user agent
- Isolated clients, entities and concerns
- Expanded documentation

## 3.0.0-dev 2020-02-18

### Changed
- Rewrote gem from scratch

### Added

- Client wrappers for REST API
- Serializers for REST API
- Client wrappers for Upload API
- Serializers for Upload API
- rdoc documentation

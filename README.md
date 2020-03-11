# Ruby integration for Uploadcare

![license](https://img.shields.io/badge/license-MIT-brightgreen.svg)

Uploadcare Ruby integration handles uploads and further operations with files by
wrapping Upload and REST APIs.

* [Installation](#installation)
* [Usage](#usage)
* [Useful links](#useful-links)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'uploadcare-ruby'
```

And then execute:

    $ bundle

If already not, create your project in [Uploadcare dashboard](https://uploadcare.com/dashboard/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-ruby) and copy
its API keys from there.

Set your Uploadcare keys in config file or through environment variables
`UPLOADCARE_PUBLIC_KEY` and `UPLOADCARE_SECRET_KEY`.

Or configure your app yourself if you are using different way of storing keys.
Gem configuration is available in `Uploadcare.configuration`. Full list of
settings can be seen in [`lib/uploadcare/default_configuration.rb`](lib/uploadcare/default_configuration.rb)

```bash
export UPLOADCARE_PUBLIC_KEY=demopublickey
export UPLOADCARE_SECRET_KEY=demoprivatekey
```

## Usage

This section contains practical usage examples. Please note, everything that
follows gets way more clear once you've looked through our
[docs](https://uploadcare.com/docs/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-ruby).

### Uploading and storing a single file

Using Uploadcare is simple, and here are the basics of handling files.

```ruby
@file_to_upload = File.open("your-file.png")

@uc_file = Uploadcare::Uploader.upload(@file_to_upload)

@uc_file.uuid
# => "dc99200d-9bd6-4b43-bfa9-aa7bfaefca40"

# URL for the file, can be used with your website or app right away
@uc_file.cdn_url
# => "https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/"
```

Your might then want to store or delete the uploaded file. Storing files could
be crucial if you aren't using the “Automatic file storing” option for your
Uploadcare project. If not stored manually or automatically, files get deleted
within a 24-hour period.

```ruby
# that's how you store a file
@uc_file.store
# => #<Uploadcare::Api::File ...

# and that works for deleting it
@uc_file.delete
# => #<Uploadcare::Api::File ...
```

### Uploads

Uploadcare supports multiple ways to upload files:

```ruby
# Smart upload - detects type of passed object and picks appropriate upload method
Uploadcare::Uploader.upload('https://placekitten.com/96/139')
```

There are explicit ways to select upload type:

```ruby
files = [File.open('1.jpg'), File.open('1.jpg']
Uploadcare::Uploader.upload_files(files)

Uploadcare::Uploader.upload_from_url('https://placekitten.com/96/139')

# multipart upload - can be useful for files bigger than 10 mb
Uploadcare::Uploader.multipart_upload(File.open('big_file.bin'))
```

### Upload options

You can override global [`:autostore`](#initialization) option for each upload request:

```ruby
@api.upload(files, store: true)
@api.upload_from_url(url, store: :auto)
```

### Api
Most methods are also available through `Uploadcare::Api` object:
```ruby
# Same as Uploadcare::Uploader.upload
Uploadcare::Api.upload('https://placekitten.com/96/139')
```

### Entity object

Entities are representations of objects in Uploadcare cloud.

#### File

File entity contains its metadata.

```ruby
@file = Uploadcare::File.file('FILE_ID_IN_YOUR_PROJECT')
{"datetime_removed"=>nil,
 "datetime_stored"=>"2020-01-16T15:03:15.315064Z",
 "datetime_uploaded"=>"2020-01-16T15:03:14.676902Z",
 "image_info"=>
  {"color_mode"=>"RGB",
   "orientation"=>nil,
   "format"=>"JPEG",
   "sequence"=>false,
   "height"=>183,
   "width"=>190,
   "geo_location"=>nil,
   "datetime_original"=>nil,
   "dpi"=>nil},
 "is_image"=>true,
 "is_ready"=>true,
 "mime_type"=>"image/jpeg",
 "original_file_url"=>
  "https://ucarecdn.com/FILE_ID_IN_YOUR_PROJECT/imagepng.jpeg",
 "original_filename"=>"image.png.jpeg",
 "size"=>5345,
 "url"=>
  "https://api.uploadcare.com/files/FILE_ID_IN_YOUR_PROJECT/",
 "uuid"=>"8f64f313-e6b1-4731-96c0-6751f1e7a50a"}

@file.store # stores file, returns updated metadata

@file.delete #deletes file. Returns updated metadata
```

Metadata of deleted files is stored permanently.

#### FileList

`Uploadcare::Entity::FileList` represents the whole collection of files (or it's
subset) and provides a way to iterate through it, making pagination transparent.
FileList objects can be created using `Uploadcare::Entity.file_list` method.

```ruby
@list = Uploadcare::Entity.file_list # => instance of Uploadcare::Api::FileList
```

This method accepts some options to controll which files should be fetched and
how they should be fetched:

- **:limit** — Controls page size. Accepts values from 1 to 1000, defaults to 100.
- **:stored** — Can be either `true` or `false`. When true, file list will contain only stored files. When false — only not stored.
- **:removed** — Can be either `true` or `false`. When true, file list will contain only removed files. When false — all except removed. Defaults to false.
- **:ordering** — Controls the order of returned files. Available values: `datetime_updated`, `-datetime_updated`, `size`, `-size`. Defaults to `datetime_uploaded`. More info can be found [here](https://uploadcare.com/documentation/rest/#file-files/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-ruby).
- **:from** — Specifies the starting point for a collection. Resulting collection will contain files from the given value and to the end in a direction set by an **ordering** option. When files are ordered by `datetime_updated` in any direction, accepts either a `DateTime` object or an ISO 8601 string. When files are ordered by size, accepts non-negative integers (size in bytes). More info can be found [here](https://uploadcare.com/documentation/rest/#file-files/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-ruby).

Options used to create a file list can be accessed through `#options` method.
Note that, once set, they don't affect file fetching process anymore and are
stored just for your convenience. That is why they are frozen.

```ruby
options = {
  limit: 10,
  stored: true,
  ordering: '-datetime_uploaded',
  from: "2017-01-01T00:00:00",
}
@list = @api.file_list(options)
```

#### Group

Groups are structures intended to organize sets of separate files. Each group is
assigned UUID. Note, group UUIDs include a `~#{files_count}` part at the end.
That's a requirement of our API.

```ruby
# group can be created from an array of Uploadcare files
@files_ary = [@file, @file2]
@files = Uploadcare::Uploader.upload @files_ary
@group = Uploadcare::Group.create @files
```

#### Webhook
https://uploadcare.com/docs/api_reference/rest/webhooks/

You can use webhooks to provide notifications about your uploads to target urls.
This gem lets you create and manage webhooks.

```ruby
Uploadcare::Webhook.create('example.com/listen', event: 'file.uploaded')
```

#### Project

`Project` provides basic info about the connected Uploadcare project. That
object is also an Hashie::Mash, so every methods out of
[these](https://uploadcare.com/documentation/rest/#project/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-ruby) will work.

```ruby
@project = Uploadcare::Project.project
# => #<Uploadcare::Api::Project collaborators=[], name="demo", pub_key="demopublickey", autostore_enabled=true>

@project.name
# => "demo"

@project.collaborators
# => []
# while that one was empty, it usually goes like this:
# [{"email": collaborator@gmail.com, "name": "Collaborator"}, {"email": collaborator@gmail.com, "name": "Collaborator"}]
```

## Useful links

* [Development](./DEVELOPMENT.md)  
* [Uploadcare documentation](https://uploadcare.com/docs/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-ruby)  
* [Upload API reference](https://uploadcare.com/api-refs/upload-api/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-ruby)  
* [REST API reference](https://uploadcare.com/api-refs/rest-api/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-ruby)  
* [Changelog](./CHANGELOG.md)  
* [Contributing guide](https://github.com/uploadcare/.github/blob/master/CONTRIBUTING.md)  
* [Security policy](https://github.com/uploadcare/uploadcare-ruby/security/policy)  
* [Support](https://github.com/uploadcare/.github/blob/master/SUPPORT.md)  

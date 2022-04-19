# Ruby integration for Uploadcare

![license](https://img.shields.io/badge/license-MIT-brightgreen.svg)
[![Build Status][actions-img]][actions-badge]
[![Uploadcare stack on StackShare][stack-img]][stack]
<!--[![Coverage Status][coverals-img]][coverals]-->

[actions-badge]: https://github.com/uploadcare/uploadcare-ruby/actions/workflows/ruby.yml
[actions-img]: https://github.com/uploadcare/uploadcare-ruby/actions/workflows/ruby.yml/badge.svg
[coverals-img]: https://coveralls.io/repos/github/uploadcare/uploadcare-ruby/badge.svg?branch=main
[coverals]: https://coveralls.io/github/uploadcare/uploadcare-ruby?branch=main
[stack-img]: https://img.shields.io/badge/tech-stack-0690fa.svg?style=flat
[stack]: https://stackshare.io/uploadcare/stacks/

Uploadcare Ruby integration handles uploads and further operations with files by
wrapping Upload and REST APIs.

* [Installation](#installation)
* [Usage](#usage)
  * [Uploading files](#uploading-files)
    * [Uploading and storing a single file](#uploading-and-storing-a-single-file)
    * [Multiple ways to upload files](#multiple-ways-to-upload-files)
    * [Uploading options](#uploading-options)
  * [File management](#file-management)
    * [File](#file)
    * [FileList](#filelist)
    * [Pagination](#pagination)
    * [Group](#group)
    * [GroupList](#grouplist)
    * [Webhook](#webhook)
    * [Project](#project)
    * [Conversion](#conversion)
* [Useful links](#useful-links)

## Requirements
* ruby 2.4+

## Compatibility

Note that `uploadcare-ruby` **3.x** is not backward compatible with
**[2.x](https://github.com/uploadcare/uploadcare-ruby/tree/v2.x)**.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "uploadcare-ruby"
```

And then execute:

    $ bundle

If already not, create your project in [Uploadcare dashboard](https://app.uploadcare.com/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-ruby) and copy
its API keys from there.

Set your Uploadcare keys in config file or through environment variables:
```bash
export UPLOADCARE_PUBLIC_KEY=demopublickey
export UPLOADCARE_SECRET_KEY=demoprivatekey
```

Or configure your app yourself if you are using different way of storing keys.
Gem configuration is available in `Uploadcare.configuration`. Full list of
settings can be seen in [`lib/uploadcare.rb`](lib/uploadcare.rb)

```ruby
# your_config_initializer_file.rb
Uploadcare.config.public_key = "demopublickey"
Uploadcare.config.secret_key = "demoprivatekey"
```

## Usage

This section contains practical usage examples. Please note, everything that
follows gets way more clear once you've looked through our
[docs](https://uploadcare.com/docs/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-ruby)
and [Upload](https://uploadcare.com/api-refs/upload-api/) and [REST](https://uploadcare.com/api-refs/rest-api/) API refs.

You can also find an example project [here](https://github.com/uploadcare/uploadcare-rails-example).

### Uploading files
#### Uploading and storing a single file

Using Uploadcare is simple, and here are the basics of handling files.

```ruby
@file_to_upload = File.open("your-file.png")

@uc_file = Uploadcare::Uploader.upload(@file_to_upload)

@uc_file.uuid
# => "dc99200d-9bd6-4b43-bfa9-aa7bfaefca40"

# URL for the file, can be used with your website or app right away
@uc_file.url
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

#### Multiple ways to upload files

Uploadcare supports multiple ways to upload files:

```ruby
# Smart upload - detects type of passed object and picks appropriate upload method
# If you have a large file (more than 100Mb / 10485760 bytes), the uploader will automatically process it with a multipart upload

Uploadcare::Uploader.upload("https://placekitten.com/96/139")
```

There are explicit ways to select upload type:

```ruby
files = [File.open("1.jpg"), File.open("1.jpg"]
Uploadcare::Uploader.upload_files(files)

Uploadcare::Uploader.upload_from_url("https://placekitten.com/96/139")
```
It is possible to track progress of the upload-from-URL process. To do that, you should specify the `async` option and get a token:

```ruby
Uploadcare::Uploader.upload_from_url("https://placekitten.com/96/139", async: true)
# => "c6e31082-6bdc-4cb3-bef5-14dd10574d72"
```

After the request for uploading-from-URL is sent, you can check the progress of the upload by sending the `get_upload_from_url_status` request:

```ruby
Uploadcare::Uploader.get_upload_from_url_status("1251ee66-3631-4416-a2fb-96ba59f5a515")
# => Success({:size=>28511, :total=>28511, :done=>28511, :uuid=>"b829753b-6b64-4989-a167-ef15e4f3d190", :file_id=>"b859753b-zb64-4989-a167-ef15e4f3a190", :original_filename=>"video.ogg", :is_image=>false, :is_stored=>false, :image_info=>nil, :video_info=>nil, :is_ready=>true, :filename=>"video.ogg", :mime_type=>"audio/ogg", :status=>"success"})
```

In case of the `async` option is disabled, uploadcare-ruby tries to request the upload status several times (depending on the `max_request_tries` config param) and then returns uploaded file attributes.

```ruby
# multipart upload - can be useful for files bigger than 10 mb
Uploadcare::Uploader.multipart_upload(File.open("big_file.bin"), store: true)
```

For the multipart upload you can pass a block to add some additional logic after each file chunk is uploaded.
For example to track file uploading progress you can do something like this:

```ruby
file = File.open("big_file.bin")
progress = 0
Uploadcare::Uploader.multipart_upload(file, store: true) do |options|
  progress += (100.0 / options[:links_count])
  puts "PROGRESS = #{progress}"
end
```
Output of the code above looks like:
```console
PROGRESS = 4.545454545454546
PROGRESS = 9.090909090909092
PROGRESS = 13.636363636363637
...
```
Options available in a block:
- **:chunk_size** - size of each chunk in bytes;
- **:object** - file object which is going to be uploaded;
- **:offset** - offset from the beginning of a File object in bytes;
- **:link_id** - index of a link provided by Uploadcare API. Might be treated as index of a chunk;
- **:links** - array of links for uploading file's chunks;
- **:links_count** - count of the array of links.

#### Uploading options

You can override global [`:autostore`](#initialization) option for each upload request:

```ruby
@api.upload(files, store: true)
@api.upload_from_url(url, store: :auto)
```

### File management

Entities are representations of objects in Uploadcare cloud.

#### File

File entity contains its metadata.

```ruby
@file = Uploadcare::File.file("FILE_ID_IN_YOUR_PROJECT")
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

@file.copy # copies file, returns a new (copied) file metadata

@file.store # stores file, returns updated metadata

@file.delete #deletes file. Returns updated metadata
```

The File object is also can be converted if it is a document or a video file. Imagine, you have a document file:

```ruby
@file = Uploadcare::File.file("FILE_ID_IN_YOUR_PROJECT")
```

To convert it to an another file, just do:

```ruby
@converted_file = @file.convert_document({ format: "png", page: "1" }, store: true)
# => {
#    "uuid"=>"<NEW_FILE_UUID>"}
#    ...other file info...
# }
# OR
# Failure({:"<FILE_UUID>/document/-/format/png/-/page/1/"=>"the target_format is not a supported 'to' format for this source file. <you_source_file_extension> -> png"})
```

Same works for video files:

```ruby
@converted_file = @file.convert_video(
  {
    format: "ogg",
    quality: "best",
    cut: { start_time: "0:0:0.1", length: "end" },
    size: { resize_mode: "change_ratio", width: "600", height: "400" },
    thumb: { N: 1, number: 2 }
  },
  store: true
)
# => {
#    "uuid"=>"<NEW_FILE_UUID>"}
#    ...other file info...
# }
# OR
# Failure({:"<FILE_UUID>/video/-/size/600x400/preserve_ratio/-/quality/best/-/format/ogg/-/cut/0:0:0.1/end/-/thumbs~1/2/"=>"CDN Path error: Failed to parse remainder \"/preserve_ratio\" of \"size/600x400/preserve_ratio\""})
```

More about file conversion [here](#conversion).
Metadata of deleted files is stored permanently.

#### FileList

`Uploadcare::FileList` represents the whole collection of files (or it's
subset) and provides a way to iterate through it, making pagination transparent.
FileList objects can be created using `Uploadcare::FileList.file_list` method.

```ruby
@list = Uploadcare::FileList.file_list
# Returns instance of Uploadcare::Entity::FileList
<Hashie::Mash
  next=nil
  per_page=100
  previous=nil
  results=[
    # Array of Entity::File
  ]
  total=8>
# load last page of files
@files = @list.files
# load all files
@all_files = @list.load
```

This method accepts some options to control which files should be fetched and
how they should be fetched:

- **:limit** — Controls page size. Accepts values from 1 to 1000, defaults to 100.
- **:stored** — Can be either `true` or `false`. When true, file list will contain only stored files. When false — only not stored.
- **:removed** — Can be either `true` or `false`. When true, file list will contain only removed files. When false — all except removed. Defaults to false.
- **:ordering** — Controls the order of returned files. Available values: `datetime_updated`, `-datetime_updated`, `size`, `-size`. Defaults to `datetime_uploaded`. More info can be found [here](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/filesList).
- **:from** — Specifies the starting point for a collection. Resulting collection will contain files from the given value and to the end in a direction set by an **ordering** option. When files are ordered by `datetime_updated` in any direction, accepts either a `DateTime` object or an ISO 8601 string. When files are ordered by size, accepts non-negative integers (size in bytes). More info can be found [here](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/filesList).

Options used to create a file list can be accessed through `#options` method.
Note that, once set, they don't affect file fetching process anymore and are
stored just for your convenience. That is why they are frozen.

```ruby
options = {
  limit: 10,
  stored: true,
  ordering: "-datetime_uploaded",
  from: "2017-01-01T00:00:00",
}
@list = @api.file_list(options)
```

To simply get all associated objects:
```ruby
@list.all # => returns Array of Files
```

#### Pagination

Initially, `FileList` is a paginated collection. It can be navigated using following methods:
```ruby
  @file_list = Uploadcare::FileList.file_list
  # Let's assume there are 250 files in cloud. By default, UC loads 100 files. To get next 100 files, do:
  @next_page = @file_list.next_page
  # To get previous page:
  @previous_page = @file_list.previous_page
```

Alternatively, it's possible to iterate through full list of groups or files with `each`:
```ruby
@list.each do |file|
  p file.url
end
```

#### Group

Groups are structures intended to organize sets of separate files. Each group is
assigned UUID. Note, group UUIDs include a `~#{files_count}` part at the end.
That's a requirement of our API.

```ruby
# group can be created from an array of Uploadcare files (UUIDs)
@file = "134dc30c-093e-4f48-a5b9-966fe9cb1d01"
@file2 = "134dc30c-093e-4f48-a5b9-966fe9cb1d02"
@files_ary = [@file, @file2]
@group = Uploadcare::Group.create @files

# group can be stored by group ID. It means that all files of a group will be stored on Uploadcare servers permanently
Uploadcare::Group.store(group.id)
```

#### GroupList
`GroupList` is a list of `Group`

```ruby
@group_list = Uploadcare::GroupList.list
# To get an array of groups:
@groups = @group_list.all
```

This is a paginated list, so [pagination](#Pagination) methods apply

#### Webhook
https://uploadcare.com/docs/api_reference/rest/webhooks/

You can use webhooks to provide notifications about your uploads to target urls.
This gem lets you create and manage webhooks.

Each webhook payload can be signed with a secret (the `signing_secret` option) to ensure that the request comes from the expected sender.
More info about secure webhooks [here](https://uploadcare.com/docs/security/secure-webhooks/).

```ruby
Uploadcare::Webhook.create(target_url: "https://example.com/listen", event: "file.uploaded", is_active: true, signing_secret: "some-secret")
Uploadcare::Webhook.update(<webhook_id>, target_url: "https://newexample.com/listen/new", event: "file.uploaded", is_active: true, signing_secret: "some-secret")
Uploadcare::Webhook.delete("https://example.com/listen")
Uploadcare::Webhook.list
```

##### Webhook signature verification

The gem has a helper class to verify a webhook signature from headers —
`Uploadcare::Param::WebhookSignatureVerifier`. This class accepts three
important options:

- **:webhook_body** — this option represents parameters received in the webhook
  request in the JSON format.
  **NOTE**: if you're using Rails, you should exclude options `controller`,
  `action` and `post` from the `webhook_body`.
- **:signing_secret** — the secret that was set while creating/updating a
  webhook. This option can be specified as an ENV var with the name
  `UC_SIGNING_SECRET` — then no need to send it to the verifier class.
- **:x_uc_signature_header** — the content of the `X-Uc-Signature` HTTP header
  in the webhook request.

Using the `Uploadcare::Param::WebhookSignatureVerifier` class example:

```ruby
  webhook_body = '{...}'

signing_secret = "12345X"
x_uc_signature_header = "v1=9b31c7dd83fdbf4a2e12b19d7f2b9d87d547672a325b9492457292db4f513c70"

Uploadcare::Param::WebhookSignatureVerifier.valid?(signing_secret: signing_secret, x_uc_signature_header: x_uc_signature_header, webhook_body: webhook_body)
```

You can write your verifier. Example code:

```ruby
webhook_body_json = '{...}'

signing_secret = ENV['UC_SIGNING_SECRET']
x_uc_signature_header = "v1=f4d859ed2fe47b9a4fcc81693d34e58ad12366a841e58a7072c1530483689cc0"

digest = OpenSSL::Digest.new('sha256')

calculated_signature = "v1=#{OpenSSL::HMAC.hexdigest(digest, signing_secret.force_encoding("utf-8"), webhook_body_json.force_encoding("utf-8"))}"

if calculated_signature == x_uc_signature_header
  puts "WebHook signature matches!"
else
  puts "WebHook signature mismatch!"
end
```

#### Project

`Project` provides basic info about the connected Uploadcare project. That
object is also an Hashie::Mash, so every methods out of
[these](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/projectInfo) will work.

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

#### Conversion

##### Video

After each video file upload you obtain a file identifier in UUID format.
Then you can use this file identifier to convert your video in multiple ways:

```ruby
Uploadcare::VideoConverter.convert(
  [
    {
      uuid: "dc99200d-9bd6-4b43-bfa9-aa7bfaefca40",
      size: { resize_mode: "change_ratio", width: "600", height: "400" },
      quality: "best",
      format: "ogg",
      cut: { start_time: "0:0:0.0", length: "0:0:1.0" },
      thumbs: { N: 2, number: 1 }
    }
  ],
  store: false
)
```
This method accepts options to set properties of an output file:

- **uuid** — the file UUID-identifier.
- **size**:
  - **resize_mode** - size operation to apply to a video file. Can be `preserve_ratio (default)`, `change_ratio`, `scale_crop` or `add_padding`.
  - **width** - width for a converted video.
  - **height** - height for a converted video.

```
  NOTE: you can choose to provide a single dimension (width OR height).
        The value you specify for any of the dimensions should be a non-zero integer divisible by 4
```

- **quality** - sets the level of video quality that affects file sizes and hence loading times and volumes of generated traffic. Can be `normal (default)`, `better`, `best`, `lighter`, `lightest`.
- **format** - format for a converted video. Can be `mp4 (default)`, `webm`, `ogg`.
- **cut**:
  - **start_time** - defines the starting point of a fragment to cut based on your input file timeline.
  - **length** - defines the duration of that fragment.
- **thumbs**:
  - **N** - quantity of thumbnails for your video - non-zero integer ranging from 1 to 50; defaults to 1.
  - **number** - zero-based index of a particular thumbnail in a created set, ranging from 1 to (N - 1).
- **store** - a flag indicating if Uploadcare should store your transformed outputs.

```ruby
# Response
{
  :result => [
    {
      :original_source=>"dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/video/-/size/600x400/change_ratio/-/quality/best/-/format/ogg/-/cut/0:0:0.0/0:0:1.0/-/thumbs~2/1/",
      :token=>911933811,
      :uuid=>"6f9b88bd-625c-4d60-bfde-145fa3813d95",
      :thumbnails_group_uuid=>"cf34c5a1-8fcc-4db2-9ec5-62c389e84468~2"
    }
  ],
  :problems=>{}
}
```
Params in the response:
- **result** - info related to your transformed output(-s):
  - **original_source** - built path for a particular video with all the conversion operations and parameters.
  - **token** - a processing job token that can be used to get a [job status](https://uploadcare.com/docs/transformations/video-encoding/#status) (see below).
  - **uuid** - UUID of your processed video file.
  - **thumbnails_group_uuid** - holds :uuid-thumb-group, a UUID of a [file group](https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/groupsList) with thumbnails for an output video, based on the thumbs [operation](https://uploadcare.com/docs/transformations/video-encoding/#operation-thumbs) parameters.
- **problems** - problems related to your processing job, if any.

To convert multiple videos just add params as a hash for each video to the first argument of the `Uploadcare::VideoConverter#convert` method:

```ruby
Uploadcare::VideoConverter.convert(
  [
    { video_one_params }, { video_two_params }, ...
  ],
  store: false
)
```


To check a status of a video processing job you can simply use appropriate method of `Uploadcare::VideoConverter`:

```ruby
token = 911933811
Uploadcare::VideoConverter.status(token)
```
`token` here is a processing job token, obtained in a response of a convert video request.

```ruby
# Response
{
  :status => "finished",
  :error => nil,
  :result => {
    :uuid => "dc99200d-9bd6-4b43-bfa9-aa7bfaefca40",
    :thumbnails_group_uuid => "0f181f24-7551-42e5-bebc-14b15d9d3838~2"
  }
}
```

Params in the response:
- **status** - processing job status, can have one of the following values:
  - *pending* — video file is being prepared for conversion.
  - *processing* — video file processing is in progress.
  - *finished* — the processing is finished.
  - *failed* — we failed to process the video, see error for details.
  - *canceled* — video processing was canceled.
- **error** - holds a processing error if we failed to handle your video.
- **result** - repeats the contents of your processing output.
- **thumbnails_group_uuid** - holds :uuid-thumb-group, a UUID of a file group with thumbnails for an output video, based on the thumbs operation parameters.
- **uuid** - a UUID of your processed video file.

More examples and options can be found [here](https://uploadcare.com/docs/transformations/video-encoding/#video-encoding).

##### Document

After each document file upload you obtain a file identifier in UUID format.
Then you can use this file identifier to convert your document to a new format:

```ruby
Uploadcare::DocumentConverter.convert(
  [
    {
      uuid: "dc99200d-9bd6-4b43-bfa9-aa7bfaefca40",
      format: "pdf"
    }
  ],
  store: false
)
```
or create an image of a particular page (if using image format):
```ruby
Uploadcare::DocumentConverter.convert(
  [
    {
      uuid: "a4b9db2f-1591-4f4c-8f68-94018924525d",
      format: "png",
      page: 1
    }
  ],
  store: false
)
```

This method accepts options to set properties of an output file:

- **uuid** — the file UUID-identifier.
- **format** - defines the target format you want a source file converted to. The supported values are: `pdf` (default), `doc`, `docx`, `xls`, `xlsx`, `odt`, `ods`, `rtf`, `txt`, `jpg`, `png`. In case the format operation was not found, your input document will be converted to `pdf`.
- **page** - a page number of a multi-paged document to either `jpg` or `png`. The method will not work for any other target formats.

```ruby
# Response
{
  :result => [
    {
      :original_source=>"a4b9db2f-1591-4f4c-8f68-94018924525d/document/-/format/png/-/page/1/",
      :token=>21120220
      :uuid=>"88fe5ada-90f1-422a-a233-3a0f3a7cf23c"
    }
  ],
  :problems=>{}
}
```
Params in the response:
- **result** - info related to your transformed output(-s):
  - **original_source** - source file identifier including a target format, if present.
  - **token** - a processing job token that can be used to get a [job status](https://uploadcare.com/docs/transformations/document-conversion/#status) (see below).
  - **uuid** - UUID of your processed document file.
- **problems** - problems related to your processing job, if any.

To convert multiple documents just add params as a hash for each document to the first argument of the `Uploadcare::DocumentConverter#convert` method:

```ruby
Uploadcare::DocumentConverter.convert(
  [
    { doc_one_params }, { doc_two_params }, ...
  ],
  store: false
)
```

To check a status of a document processing job you can simply use appropriate method of `Uploadcare::DocumentConverter`:

```ruby
token = 21120220
Uploadcare::DocumentConverter.status(token)
```
`token` here is a processing job token, obtained in a response of a convert document request.

```ruby
# Response
{
  :status => "finished",
  :error => nil,
  :result => {
    :uuid => "a4b9db2f-1591-4f4c-8f68-94018924525d"
  }
}
```

Params in the response:
- **status** - processing job status, can have one of the following values:
  - *pending* — document file is being prepared for conversion.
  - *processing* — document file processing is in progress.
  - *finished* — the processing is finished.
  - *failed* — we failed to process the document, see error for details.
  - *canceled* — document processing was canceled.
- **error** - holds a processing error if we failed to handle your document.
- **result** - repeats the contents of your processing output.
- **uuid** - a UUID of your processed document file.

More examples and options can be found [here](https://uploadcare.com/docs/transformations/document-conversion/#document-conversion)

## Secure delivery

You can use custom domain and CDN provider to deliver files with authenticated URLs (see [original documentation](https://uploadcare.com/docs/security/secure_delivery/)).

To generate authenticated URL from the library, you should choose `Uploadcare::SignedUrlGenerators::AmakaiGenerator` (or create your generator implementation):
```ruby
generator = Uploadcare::SignedUrlGenerators::AmakaiGenerator.new(cdn_host: 'example.com', secret_key: 'secret_key'). Optional parameters: ttl: 300, algorithm: 'sha256'
generator.generate_url(uuid, acl = optional)

generator.generate_url("a7d5645e-5cd7-4046-819f-a6a2933bafe3") ->
https://example.com/a7d5645e-5cd7-4046-819f-a6a2933bafe3/?token=exp=1649405263~acl=/a7d5645e-5cd7-4046-819f-a6a2933bafe3/~hmac=a989cae5342f17013677f5a0e6577fc5594cc4e238fb4c95eda36634eb47018b
generator.generate_url("a7d5645e-5cd7-4046-819f-a6a2933bafe3", '/*/') ->
https://example.com/a7d5645e-5cd7-4046-819f-a6a2933bafe3/?token=exp=1649405263~acl=/*/~hmac=3ce1152c6af8864b36d4dc721f08ca3cf0b3a20278d7f849e82c6c930d48ccc1
```
## Useful links

* [Development](https://github.com/uploadcare/uploadcare-ruby/blob/main/DEVELOPMENT.md)
* [Uploadcare documentation](https://uploadcare.com/docs/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-ruby)
* [Upload API reference](https://uploadcare.com/api-refs/upload-api/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-ruby)
* [REST API reference](https://uploadcare.com/api-refs/rest-api/?utm_source=github&utm_medium=referral&utm_campaign=uploadcare-ruby)
* [Changelog](./CHANGELOG.md)
* [Contributing guide](https://github.com/uploadcare/.github/blob/master/CONTRIBUTING.md)
* [Security policy](https://github.com/uploadcare/uploadcare-ruby/security/policy)
* [Support](https://github.com/uploadcare/.github/blob/master/SUPPORT.md)

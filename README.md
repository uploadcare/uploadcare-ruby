[![Build Status](https://secure.travis-ci.org/uploadcare/uploadcare-ruby.png?branch=master)](http://travis-ci.org/uploadcare/uploadcare-ruby)

A [Ruby](https://www.ruby-lang.org/en/) wrapper for [Uploadcare](https://uploadcare.com).

## Installation

Installing `uploadcare-ruby` is quite simple and takes a couple of steps.
First of, add the following line to your app's Gemfile:

```ruby
gem 'uploadcare-ruby'
```

Once you've added the line, execute this:

```shell
$ bundle install
```

Or that (for manual install):

```shell
$ gem install uploadcare-ruby
```

## Initialization

Init is simply done through creating an API object.

```ruby
require 'uploadcare'

@api = Uploadcare::Api.new # default settings are used

@api = Uploadcare::Api.new(settings) # using user-defined settings
```

Here's how the default settings look like:

``` ruby
  {
    public_key: 'demopublickey',   # you need to override this
    private_key: 'demoprivatekey', # you need to override this
    upload_url_base: 'https://upload.uploadcare.com',
    api_url_base: 'https://api.uploadcare.com',
    static_url_base: 'https://ucarecdn.com',
    api_version: '0.3',
    cache_files: true,
    auth_scheme: :secure
  }
```

You're free to use both `demopublickey` and `demoprivatekey`
for initial testing purposes. We wipe out files loaded to our
demo account periodically. For a better experience,
consider creating an Uploadcare account. Check out
[this](http://kb.uploadcare.com/article/234-uc-project-and-account)
article to get up an running in minutes.

Please note, in order to use [Upload API](https://uploadcare.com/documentation/upload/)
you will only need the public key alone. However, using 
[REST API](https://uploadcare.com/documentation/rest/) requires you to
use both public and private keys for authentication.  
While “private key” is a common way to name a key from an
authentication key pair, the actual thing for our `auth-param` is `secret_key`.

## Usage

This section contains practical usage examples. Please note,
everything that follows gets way more clear once you've looked
through our docs [intro](https://uploadcare.com/documentation/).

### Basic usage: uploading a single file, manipulations

Using Uploadcare is simple, and here are the basics of handling files.

First of, create the API object:

```ruby
@api = Uploadcare::Api.new(CONFIG)

```

And yeah, now you can upload a file:

```ruby
@file_to_upload = File.open("your-file.png")

@uc_file = @api.upload(@file_to_upload)
# => #<Uploadcare::Api::File ...
```

Then, let's check out UUID and URL of the
file you've just uploaded:

```ruby
# file uuid (you'd probably want to store those somewhere)
@uc_file.uuid
# => "dc99200d-9bd6-4b43-bfa9-aa7bfaefca40"

# url for the file, can be used with your website or app right away
@uc_file.cdn_url
# => "https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/"
```

Your might then want to store or delete the uploaded file.
Storing files could be crucial if you aren't using the
“Automatic file storing” option for your Uploadcare project.
If not stored manually or automatically, files get deleted
within a 24-hour period.

```ruby
# that's how you store a file
@uc_file.store
# => #<Uploadcare::Api::File ...

# and that works for deleting it
@uc_file.delete
# => #<Uploadcare::Api::File ...
```

### Uploading a file from URL

Now, this one is also quick. Just pass your URL into our API
and you're good to go.

```ruby
# the smart upload
@file  = @api.upload "http://your.awesome/avatar.jpg" 
# =>  #<Uploadcare::Api::File ...

# use this one if you want to explicitly upload from URL
@file = @api.upload_from_url "http://your.awesome/avatar.jpg" 
# =>  #<Uploadcare::Api::File ...
```
Keep in mind that providing invalid URL
will raise `ArgumentError`.

### Uploading multiple files

Uploading multiple files is as simple as passing an array
of `File` instances into our API.

```ruby
file1 = File.open("path/to/your/file.png")
file2 = File.open("path/to/your/another-file.png")
files = [file1, file2]

@uc_files = @api.upload files
# => [#<Uploadcare::Api::File uuid="dc99200d-9bd6-4b43-bfa9-aa7bfaefca40">,
#     #<Uploadcare::Api::File uuid="96cdc400-adc3-435b-9c94-04cd87633fbb">]
```

In case of multiple input, the respective output would also be an array.
You can iterate through the array to address to single files.
You might also want to request more info about a file using `load_data`.

```ruby
@uc_files[0]
# => #<Uploadcare::Api::File uuid="dc99200d-9bd6-4b43-bfa9-aa7bfaefca40">

@uc_files[1].load_data
# => #<Uploadcare::Api::File uuid="96cdc400-adc3-435b-9c94-04cd87633fbb", original_file_url="https://ucarecdn.com/96cdc400-adc3-435b-9c94-04cd87633fbb/samuelzeller118195.jpg", image_info={"width"=>4896, "geo_location"=>nil, "datetime_original"=>nil, "height"=>3264}, ....>
```

### `File` object

Now that we've already outlined using arrays of `File` instances
to upload multiple files, let's fix on the `File` itself.
It's the the primary object for Uploadcare API.
Basically, it's an avatar for a file you uploaded.
And all the further operations are performed using this avatar,
the `File` object.

```ruby
@file_to_upload = File.open("your-file.png")

@uc_file = @api.upload(@file_to_upload)
# => #<Uploadcare::Api::File ...

@uc_file.uuid
# => "dc99200d-9bd6-4b43-bfa9-aa7bfaefca40"

@uc_file.cdn_url
# => "https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/"
```

Please note, all the data associated with files is only accessible
through separate HTTP requests only. So if you don't specifically
need file data (filenames, image dimensions, etc.), you'll be just
fine with using `:uuid` and `:cdn_url` methods for file output:

```erb
<img src="#{@file.cdn_url}"/>
```

Great, we've just lowered a precious loading time.
However, if you do need the data, you can always request
it manually:

```ruby
@uc_file.load_data
```

That way your file object will respond to any method described
in [API docs](https://uploadcare.com/documentation/rest/#file).
Basically, that's an an OpenStruct, so you know what to do:

```ruby
@uc_file.original_filename
# => "logo.png"

@uc_file.image_info
# => {"width"=>397, "geo_location"=>nil, "datetime_original"=>nil, "height"=>81}
```

### Raw API

Raw API is a simple interface allowing you to make
custom requests to Uploadcare REST API.
It's mainly used when you want a low-level control
over your app.

```ruby
# here's how you make any requests
@api.request :get, "/files/", {page: 2}

# and there also are shortcuts for methods
@api.get '/files', {page: 2}

@api.post ...

@api.put ...

@api.delete ...

```

All of the raw API methods return a parsed JSON response
or raise an error (handling those is done on your side in the case).


## Uploading
You can upload either File object (array of files will also cut it) or custom URL.



### Generating files from stored info
At this point you probably store your files UUIDs or CDN urls in some kind of storage.
Then you can create file object by passing them into API:

```ruby
# file by UUID
@file = @api.file "c969be02-9925-4a7e-aa6d-b0730368791c"
# => #<Uploadcare::Api::File uuid="7bb9efa4-05c0-4f36-b0ef-11a4221867f6"

# file by CDN url
@file = @api.file "https://ucarecdn.com/a8775cf7-0c2c-44fa-b071-4dd48637ecac/"
# => #<Uploadcare::Api::File uuid="7bb9efa4-05c0-4f36-b0ef-11a4221867f6"

# not that generated files aren't loaded by initializing, you need to load it.
@file.is_loaded?
# => false
```

### Operations
Uploadcare gives you some awesome CDN operations for croping, resizing, rotation, format convertation etc. You could read more at https://uploadcare.com/documentation/cdn/ .
Version 1.0.0 of the gem has no specific methods for this kind of operations, we expect to add support for it later in 1.1 releases.
For the moment all your file objects can store operations passed by cdn url:

```ruby
@file = @api.file "https://ucarecdn.com/a8775cf7-0c2c-44fa-b071-4dd48637ecac/-/crop/150x150/center/-/format/png/"
# => #<Uploadcare::Api::File uuid="a8775cf7-0c2c-44fa-b071-4dd48637ecac"

@file.operations
# => ["crop/150x150/center", "format/png"]

# note that by default :cdn_url method will return url without any operations:
@file.cdn_url
# => "https://ucarecdn.com/a8775cf7-0c2c-44fa-b071-4dd48637ecac/""

# you can pass true to :cdn_url methods to get url with included operations:
@file.cdn_url(true)
# => "https://ucarecdn.com/a8775cf7-0c2c-44fa-b071-4dd48637ecac/-/crop/150x150/center/-/format/png/"

# or call specific methods for url with or without them:
@file.cdn_url_with_operations
@file.cdn_url_without_operations
```

Until operations wrapper is released the best way for you to manage operation is simply add them to URL as a string:

```ruby
<img src="#{file.cdn_url}-/crop/#{width}x#{height}/center/"/>
# or something like that
```

### Copying files

Our API allows you to create copies of a file. There are several options for that.

First of all, you can make a copy in Uploadcare storage:

```ruby
@uc_file.internal_copy

# =>
{
  "type"=>"file",
  "result"=> {
    "uuid"=>"a191a3df-2c43-4939-9590-784aa371ad6d",
    "original_file_url"=>"https://ucarecdn.com/a191a3df-2c43-4939-9590-784aa371ad6d/19xldj.jpg",
    "image_info"=>nil,
    "datetime_stored"=>nil,
    "mime_type"=>"application/octet-stream",
    "is_ready"=>true,
    "url"=>"https://api.uploadcare.com/files/a191a3df-2c43-4939-9590-784aa371ad6d/",
    "original_filename"=>"19xldj.jpg",
    "datetime_uploaded"=>"2017-02-10T14:14:18.690581Z",
    "size"=>0,
    "is_image"=>nil,
    "datetime_removed"=>nil,
    "source"=>"/4ea293d5-153f-422f-a24e-350237109606/"
  }
}
```

A copy becomes a separate file with its own UUID and attributes.

The only (optional) argument this method takes is an options hash. Available options are:

- *store*

  By default copy is being created unstored, so it will be deleted within 24 hours. To create a stored copy pass `store: true` option to `#internal_copy` method.

  Example:

  ```ruby
  @uc_file.internal_copy(store: true)
  ```

- *strip_operations*

  If your file is an image and any operations are applied to it, then by default all of them will be also applied to a copy. You can override this passing `strip_operations: true` to `#internal_copy` method.

  Example:

  ```ruby
  file = @api.file "https://ucarecdn.com/24626d2f-3f23-4464-b190-37115ce7742a/-/resize/50x50/"
  file.internal_copy
  # => This will trigger POST /files/ with {"source": "https://ucarecdn.com/24626d2f-3f23-4464-b190-37115ce7742a/-/resize/50x50/"} in body
  file.internal_copy(strip_operations: true)
  # => This will trigger POST /files/ with {"source": "https://ucarecdn.com/24626d2f-3f23-4464-b190-37115ce7742a/"} in body
  ```

Secondly, you can copy your file to a custom storage.

```ruby
@uc_file.external_copy('my_custom_storage_name')

# => 
{
  "type"=>"url",
  "result"=>"s3://my_bucket_name/c969be02-9925-4a7e-aa6d-b0730368791c/view.png"
}
```

First argument of this method is a name of a custom storage you wish to copy your file to.

Second argument is an (optional) options hash. Available options are:

  - *make_public*

  Make a copy available via public links. Can be either `true` or `false`

  - *pattern*

  Name pattern for a copy. If parameter is omitted, custom storage pattern is used.

  - *strip_operations*

  Same as for `#internal_copy`

You can read more about about storages here: <https://uploadcare.com/documentation/storages/>, about copying files here: https://uploadcare.com/documentation/rest/#files-post

## File list and pagination
File list is a paginated collection of files for you project. You could read more at https://uploadcare.com/documentation/rest/#pagination.
In our gem file list is a single page containing 20 (by default, value may change) files and some methods for navigating through pages.

```ruby
@list = @api.file_list 1 #page number, 1 by default
# => #<Uploadcare::Api::FileList ....


# method :resulst will return you an array of files
@list.results
# => [#<Uploadcare::Api::File uuid="24626d2f-3f23-4464-b190-37115ce7742a" ...>,
#       ... 20 of them ...
#     #<Uploadcare::Api::File uuid="7bb9efa4-05c0-4f36-b0ef-11a4221867f6" ...>]


# note that every file is already loaded
@list.results[1].is_loaded?
# => true


# there is also shortcuts for you
@list.to_a
# => [#<Uploadcare::Api::File uuid="24626d2f-3f23-4464-b190-37115ce7742a" ...>,
#       ... 20 of them ...
#     #<Uploadcare::Api::File uuid="7bb9efa4-05c0-4f36-b0ef-11a4221867f6" ...>]

@list[3]
# => #<Uploadcare::Api::File ....
```

And don't forget that you can navigate throught pages:

```ruby
@list = @api.files_list 3

@list.next_page
# => #<Uploadcare::Api::FileList page=4 ....

@list.previous_page
# => #<Uploadcare::Api::FileList page=2 ....

@list.go_to 5
# => #<Uploadcare::Api::FileList page=5 ....



# there is also methods described in API docs avaliable for you:
# total pages
@list.pages
# => 16

# current page
@list.page
# => 3

# files per page
@list.per_page
# => 20

# total files in project
@list.total
# => 308
```

## Project
Project provides basic information about the connecting project.
Project object is basicly openstruct so every method described in
[API docs](https://uploadcare.com/documentation/rest/#project)
accessible to you:

```ruby
project = @api.project
# => #<Uploadcare::Api::Project collaborators=[], name="demo", pub_key="demopublickey", autostore_enabled=true>

project.name
# => "demo"

p.collaborators
# => []
# more often it should look like
# [{"email": collaborator@gmail.com, "name": "Collaborator"}, {"email": collaborator@gmail.com, "name": "Collaborator"}]
```


## Groups of files
Groups of files - https://uploadcare.com/documentation/rest/#group.
Stores files as group by the single UUID.
Note that UUID has a `~#{files_count}` part at the end and it is required by API to work properly.

```ruby
# group can be created eather by array of Uploadcare Files:
@files_ary = [@file, @file2]
@files = @api.upload @files_ary
@group = @api.create_group @files
# => #<Uploadcare::Api::Group uuid="0d192d66-c7a6-4465-b2cd-46716c5e3df3~2", files_count=2 ...

# or by array of strings containing UUIDs
@uuids_ary = ["c969be02-9925-4a7e-aa6d-b0730368791c", "c969be02-9925-4a7e-aa6d-b0730368791c"]
@group = @api.create_group @uuids_ary
# => #<Uploadcare::Api::Group uuid="0d192d66-c7a6-4465-b2cd-46716c5e3df3~2", files_count=2 ...

# you can also create group object just by passing group UUID
@group_uloaded = @api.group "#{uuid}"
```

As with files, group created by passing just the UUID is not loaded by default - you need to load data manually, as it requires separate HTTP GET request.
New groups created by :create_group method is loaded by default.

```ruby
@group = @api.group "#{uuid}"

@group.is_loaded?
# => false

@group.load_data
# => #<Uploadcare::Api::Group uuid="0d192d66-c7a6-4465-b2cd-46716c5e3df3~2", files_count=2 ...

# loaded group has methods described by API docs and more importantly an array of files
# this files are loaded by default.
@group.files
# => [#<Uploadcare::Api::File uuid="24626d2f-3f23-4464-b190-37115ce7742a" ...>,
#       ... #{files_count} of them ...
#     #<Uploadcare::Api::File uuid="7bb9efa4-05c0-4f36-b0ef-11a4221867f6" ...>]
```

## Errors handling
From version 1.0.2 we have a custom exceptions which will raise when Uploadcare service return something with 4xx or 5xx HTTP status.

List of custom errors:

```ruby
400 => Uploadcare::Error::RequestError::BadRequest,
401 => Uploadcare::Error::RequestError::Unauthorized,
403 => Uploadcare::Error::RequestError::Forbidden,
404 => Uploadcare::Error::RequestError::NotFound,
406 => Uploadcare::Error::RequestError::NotAcceptable,
408 => Uploadcare::Error::RequestError::RequestTimeout,
422 => Uploadcare::Error::RequestError::UnprocessableEntity,
429 => Uploadcare::Error::RequestError::TooManyRequests,
500 => Uploadcare::Error::ServerError::InternalServerError,
502 => Uploadcare::Error::ServerError::BadGateway,
503 => Uploadcare::Error::ServerError::ServiceUnavailable,
504 => Uploadcare::Error::ServerError::GatewayTimeout
```

so now you could escape particular error (in that case 404: Not Found error):

```ruby
begin
  @connection.send :get, '/random_url/', {}
rescue Uploadcare::Error::RequestError::NotFound => e
  nil
end
```

... any request error (covers all 4xx status codes): 

```ruby
begin
  @connection.send :get, '/random_url/', {}
rescue Uploadcare::Error::RequestError => e
  nil
end
```

...and actually any Uploadcare service errors:

```ruby
begin
  @connection.send :get, '/random_url/', {}
rescue Uploadcare::Error => e
  nil
end
```

Please note what almost all actions depends on Uploadcare servers and it will be wise of you to expect that servers will return error code (at least some times).

## Testing

Run `bundle exec rspec`.

To run tests with your own keys, make a `spec/config.yml` file like this:

```yaml
public_key: 'PUBLIC KEY'
private_key: 'PRIVATE KEY'
```

## Contributors

This is open source so fork, hack, request a pull — get a discount.

- [@romanonthego](https://github.com/romanonthego)
- [@vizvamitra](https://github.com/vizvamitra)
- [@dmitry-mukhin](https://github.com/dmitry-mukhin)
- [@zenati](https://github.com/zenati)
- [@renius](https://github.com/renius)

## Security issues

If you think you ran into something in Uploadcare libraries
which might have security implications, please hit us up at
[bugbounty@uploadcare.com](mailto:bugbounty@uploadcare.com)
or Hackerone.

We'll contact you personally in a short time to fix an issue
through co-op and prior to any public disclosure.

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

### `File` object from UUID or CDN URL

`File` objects are needed to manipulate files on our CDN.
The usual case would be you as a client storing file UUIDs
or CDN URLs somewhere on your side, e.g. in a database.
This is how you can use those to create `File` objects:

```ruby
# file object from UUID
@file = @api.file "dc99200d-9bd6-4b43-bfa9-aa7bfaefca40"
# => #<Uploadcare::Api::File uuid="dc99200d-9bd6-4b43-bfa9-aa7bfaefca40"

# file object from CDN URL
@file = @api.file "https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/"
# => #<Uploadcare::Api::File uuid="dc99200d-9bd6-4b43-bfa9-aa7bfaefca40"

# note, files you generate won't be loaded on init,
# you'll need to load those manually
@file.is_loaded?
# => false
```

### Operations

Another way to mainpulate files on CDN is through operations.
This is particularly useful for images.
We've got on-the-fly crop, resize, rotation, format conversions, and
[more](https://uploadcare.com/documentation/cdn/).
Image operations are there to help you build responsive designs,
generate thumbnails and galleries, change formats, etc.
Currently, this gem has no specific methods for image operations,
we're planning to implement those in further versions.
However, we do support applying image operations through
adding them to CDN URLs. That's an Uploadcare CDN-native
way described in our [docs](https://uploadcare.com/documentation/cdn/).

```ruby
@file = @api.file "https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/-/crop/150x150/center/-/format/png/"
# => #<Uploadcare::Api::File uuid="dc99200d-9bd6-4b43-bfa9-aa7bfaefca40"

@file.operations
# => ["crop/150x150/center", "format/png"]

# note that by default :cdn_url method returns URLs with no operations:
@file.cdn_url
# => "https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/""

# you can pass "true" into the :cdn_url method to get URL including operations:
@file.cdn_url(true)
# => "https://ucarecdn.com/a8775cf7-0c2c-44fa-b071-4dd48637ecac/-/crop/150x150/center/-/format/png/"

# there also are specific methods to either dump or include image operations
# in the output URL:
@file.cdn_url_with_operations
@file.cdn_url_without_operations
```

While there's no operation wrapper, the best way of handling operations
is through adding them to URLs as strings:

```ruby
<img src="#{file.cdn_url}-/crop/#{width}x#{height}/center/"/>
# or something like that
```

### Copying files

You can also create file copies using our API.
There are multiple ways of creating those.
Also, copying is important for image files because
it allows you to “apply” all the CDN operations
specified in the source URL to a separate static image.

First of all, a copy of your file can be put in the Uploadcare storage.
This is called “internal copy”, and here's how it works:

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

Once the procedure is complete, a copy would be a separate file
with its own UUID and attributes.

`#internal_copy` can optionally be used with the options hash argument.
The available options are:

- *store*

  By default a copy is created without “storing”.
  Which means it will be deleted within a 24-hour period.
  You can make your output copy permanent by passing the
  `store: true` option to the `#internal_copy` method.

  Example:

  ```ruby
  @uc_file.internal_copy(store: true)
  ```

- *strip_operations*

  If your file is an image and you applied some operations to it,
  then by default the same set of operations is also applied to a copy.
  You can override this by passing `strip_operations: true` to the
  `#internal_copy` method.

  Example:

  ```ruby
  file = @api.file "https://ucarecdn.com/24626d2f-3f23-4464-b190-37115ce7742a/-/resize/50x50/"
  file.internal_copy
  # => This will trigger POST /files/ with {"source": "https://ucarecdn.com/24626d2f-3f23-4464-b190-37115ce7742a/-/resize/50x50/"} in the body
  file.internal_copy(strip_operations: true)
  # => This will trigger POST /files/ with {"source": "https://ucarecdn.com/24626d2f-3f23-4464-b190-37115ce7742a/"} in the body
  ```

Another option is copying your file to a custom storage.
We call it “external copy” and here's the usage example:

```ruby
@uc_file.external_copy('my_custom_storage_name')

# => 
{
  "type"=>"url",
  "result"=>"s3://my_bucket_name/c969be02-9925-4a7e-aa6d-b0730368791c/view.png"
}
```

First argument of the `#external_copy` method is a name of
a custom destination storage for your file.

There's also an optional second argument — options hash. The available options are:

  - *make_public*

  Make a copy available via public links. Can be either `true` or `false`.

  - *pattern*

  Name pattern for a copy. If the parameter is omitted, custom storage pattern is used.

  - *strip_operations*

  Same as for `#internal_copy`

You might want to learn more about
[storage options](https://uploadcare.com/documentation/storages/) or
[copying files](https://uploadcare.com/documentation/rest/#files-post)
with Uploadcare. 

### `Group` object

Groups are structures intended to organize sets of separate files.
Each group is assigned UUID.
Note, group UUIDs include a `~#{files_count}` part at the end.
That's a requirement of our API.

```ruby
# group can be created from an array of Uploadcare files
@files_ary = [@file, @file2]
@files = @api.upload @files_ary
@group = @api.create_group @files
# => #<Uploadcare::Api::Group uuid="0d192d66-c7a6-4465-b2cd-46716c5e3df3~2", files_count=2 ...

# another way to from a group is via an array of strings holding UUIDs
@uuids_ary = ["c969be02-9925-4a7e-aa6d-b0730368791c", "c969be02-9925-4a7e-aa6d-b0730368791c"]
@group = @api.create_group @uuids_ary
# => #<Uploadcare::Api::Group uuid="0d192d66-c7a6-4465-b2cd-46716c5e3df3~2", files_count=2 ...

# also, you can create a group object via group UUID
@group_uloaded = @api.group "#{uuid}"
```

As with files, groups created via UUIDs are not loaded by default.
You need to load the data manually, as it requires a separate
HTTP GET request. New groups created with the `:create_group` method
are loaded by default.

```ruby
@group = @api.group "#{uuid}"

@group.is_loaded?
# => false

@group.load_data
# => #<Uploadcare::Api::Group uuid="0d192d66-c7a6-4465-b2cd-46716c5e3df3~2", files_count=2 ...

# once a group is loaded, you can use any methods described in our API docs
# the files within a loaded group are loaded by default
@group.files
# => [#<Uploadcare::Api::File uuid="24626d2f-3f23-4464-b190-37115ce7742a" ...>,
#       ... #{files_count} of them ...
#     #<Uploadcare::Api::File uuid="7bb9efa4-05c0-4f36-b0ef-11a4221867f6" ...>]
```

Check out our docs to learn more about
[groups](https://uploadcare.com/documentation/rest/#group).

### File lists and pagination

File list is a paginated collection of files. Such lists are created
to better represent the contents of your project.
For this gem, a file list would be a single page containing
20 files (you can override the number).
There also are methods for navigating through pages.
You can find more info about pagination
[here](https://uploadcare.com/documentation/rest/#pagination).

```ruby
@list = @api.file_list 1 # page number, 1 is the default
# => #<Uploadcare::Api::FileList ....


# method :results returns an array of files
@list.results
# => [#<Uploadcare::Api::File uuid="24626d2f-3f23-4464-b190-37115ce7742a" ...>,
#       ... 20 of them ...
#     #<Uploadcare::Api::File uuid="7bb9efa4-05c0-4f36-b0ef-11a4221867f6" ...>]


# note, every file is already loaded
@list.results[1].is_loaded?
# => true


# we've also added some shortcuts
@list.to_a
# => [#<Uploadcare::Api::File uuid="24626d2f-3f23-4464-b190-37115ce7742a" ...>,
#       ... 20 of them ...
#     #<Uploadcare::Api::File uuid="7bb9efa4-05c0-4f36-b0ef-11a4221867f6" ...>]

@list[3]
# => #<Uploadcare::Api::File ....
```

Here's how we handle navigating through pages:

```ruby
@list = @api.files_list 3

@list.next_page
# => #<Uploadcare::Api::FileList page=4 ....

@list.previous_page
# => #<Uploadcare::Api::FileList page=2 ....

@list.go_to 5
# => #<Uploadcare::Api::FileList page=5 ....

# of course, you can go with any of the methods
# described in our API docs
# total pages
@list.pages
# => 16

# current page
@list.page
# => 3

# files per page
@list.per_page
# => 20

# total files in a project
@list.total
# => 308
```

### `Project` object

`Project` provides basic info about the connected Uploadcare project.
That object is also an OpenStruct, so every methods out of
[these](https://uploadcare.com/documentation/rest/#project) will work.

```ruby
project = @api.project
# => #<Uploadcare::Api::Project collaborators=[], name="demo", pub_key="demopublickey", autostore_enabled=true>

project.name
# => "demo"

p.collaborators
# => []
# while that one was empty, it usually goes like this:
# [{"email": collaborator@gmail.com, "name": "Collaborator"}, {"email": collaborator@gmail.com, "name": "Collaborator"}]
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

### Error handling

Starting from the version 1.0.2, we've got have custom exceptions
that will be raised in case the Uploadcare service returns
something with 4xx or 5xx HTTP status.

Check out the list of custom errors:

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

That's how you handle a particular error
(in this case, a “404: Not Found” error):

```ruby
begin
  @connection.send :get, '/random_url/', {}
rescue Uploadcare::Error::RequestError::NotFound => e
  nil
end
```

Handling any request error (covers all 4xx status codes): 

```ruby
begin
  @connection.send :get, '/random_url/', {}
rescue Uploadcare::Error::RequestError => e
  nil
end
```

Handling any Uploadcare service error:

```ruby
begin
  @connection.send :get, '/random_url/', {}
rescue Uploadcare::Error => e
  nil
end
```

Since many of the above listed things depend on Uploadcare servers,
errors might occasionally occur. Be prepared to handle those.

## Testing

For testing purposes, run `bundle exec rspec`.

Please note, if you're willing to run tests using your own keys,
make a `spec/config.yml` file containing the following:

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

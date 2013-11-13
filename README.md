[![Build Status](https://secure.travis-ci.org/uploadcare/ruby-uploadcare-api.png?branch=master)](http://travis-ci.org/uploadcare/ruby-uploadcare-api)

A ruby wrapper for uploadcare.com service.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'uploadcare-ruby'
```

And then execute:

```shell
$ bundle install
```

Or install it yourself as:

```shell
$ gem install uploadcare-ruby
```

--

## Initalizations
Just create api object - and you good to go.

```ruby
@api = Uploadcare::Api.new(CONFIG)
```

--

## Raw API
Raw API - it is a simple interface wich allows you to make custom requests to Uploadcare REST API.
Just in case you want some low-level control over your app.

```ruby
# any request
@api.request :get, "/files/", {page: 2}

# you allso have the shortcuts for methods
@api.get '/files', {page: 2}

@api.post ...

@api.put ...

@api.delete ...

```
All raw API methods returns parsed JSON response or raise an error (from which you should rescue on your own).

--

## Basic usage
Using Uploadcare is pretty easy (which is the essence of the service itself).

Create the API object:

```ruby
@api = Uploadcare::Api.new(CONFIG)

```

Upload file

```ruby
@file_to_upload = File.open("your-file.png")

@uc_file = @api.upload(@file_to_upload)
# => #<Uploadcare::Api::File ...
```

Use file

```ruby
# file uuid (you probably want to store it somewhere)
@uc_file.uuid
# => "c969be02-9925-4a7e-aa6d-b0730368791c"

# url for the file - just paste in your template and you good to go.
@uc_file.cdn_url
# => "http://www.ucarecdn.com/c969be02-9925-4a7e-aa6d-b0730368791c/"
```

Keep or delete file

```ruby
# store file (if you dont use autostore feature)
@uc_file.store
# => #<Uploadcare::Api::File ...

# and delete file
@uc_file.delete
# => #<Uploadcare::Api::File ...
```
## Uploading
You can upload either File object (array of files will also cut it) or custom URL.

### Uploading from URL
Just throw your URL into api - and you good to go.

```ruby
# smart upload
@file  = @api.upload "http://your.awesome/avatar.jpg" 
# =>  #<Uploadcare::Api::File ...

# explicitly upload from URl
@file = @api.upload_from_url "http://your.awesome/avatar.jpg" 
# =>  #<Uploadcare::Api::File ...
```
Keep in mind that invalid url will rise an ArgumentError.

### Uploading a single file
Like with URL - just start throwing your file into api

```ruby

file = File.open("path/to/your/file.png")

@uc_file  = @api.upload file
# =>  #<Uploadcare::Api::File ...

```
And thats it.

### Uploading an array of files
Uploading of an array is just as easy as uploading single files.
Note, that every object in array must be an instance of File.

```ruby
file1 = File.open("path/to/your/file.png")
file2 = File.open("path/to/your/another-file.png")
files = [file1, file2]

@uc_files = @api.upload files
# => [#<Uploadcare::Api::File uuid="24626d2f-3f23-4464-b190-37115ce7742a">,
#     #<Uploadcare::Api::File uuid="7bb9efa4-05c0-4f36-b0ef-11a4221867f6">]
```
It is returning you an array of Uploadcare files. 

```ruby
@uc_files[0]
# => #<Uploadcare::Api::File uuid="24626d2f-3f23-4464-b190-37115ce7742a">

@uc_files[0].load_data
# => #<Uploadcare::Api::File uuid="7bb9efa4-05c0-4f36-b0ef-11a4221867f6", original_file_url="http://www.ucarecdn.com/7bb9efa4-05c0-4f36-b0ef-11a4221867f6/view.png", image_info={"width"=>800, "geo_location"=>nil, "datetime_original"=>nil, "height"=>600}, ....>
```

## File
File - is the primary object for Uploadcare API. Basicly it an avatar for file, stored for you ).
So all the opertations you do - you do it with the file object.

*to do:* way to build file from UUID, CDN URL, and uploading


```ruby
@file_to_upload = File.open("your-file.png")

@uc_file = @api.upload(@file_to_upload)
# => #<Uploadcare::Api::File ...

@uc_file.uuid
# => "c969be02-9925-4a7e-aa6d-b0730368791c"

@uc_file.cdn_url
# => "http://www.ucarecdn.com/c969be02-9925-4a7e-aa6d-b0730368791c/"
```
There is one issue with files - all data associated with it accesible with separate HTTP request only.
So if don't *specificaly* need image data (like file name, geolocation data etc) - you could just use :uuid and :cdn_url methods for file output:

```erb
<img src="#{@file.cdn_url}"/>
```

And thats it. Saves you precious page loading time.

If you do however need image data - you could do it manualy:

```ruby
@uc_file.load_data
```

Then your file object will respond to any method, described in API documentations (it basicaly an OpenStruct, so you know what to do):

```ruby
@uc_file.original_filename
# => "logo.png"

@uc_file.image_info
# => {"width"=>397, "geo_location"=>nil, "datetime_original"=>nil, "height"=>81}
```

You could read more https://uploadcare.com/documentation/rest/#file .

## Files list and pagination
File lists - it is a paginated collection of files for you project. You could read more at https://uploadcare.com/documentation/rest/#pagination.
In our gem file list is a single page containing 20 (by default, value may change) files and some methods for navgiting throug pages.

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

And don't forget navigation throught pages:

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
Project object is basicly openstruct so every method described in API docs (https://uploadcare.com/documentation/rest/#project) accessible to you:

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
Note that UUID has a bit ~#{files_count} at the end and it is required by API to work properly.

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

As with files, group created by passing just the UUID is not loaded by default - you need to load data manualy, as it requires separate HTTP GET request.
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

## Testing

Run `bundle exec rspec`.

To run tests with your own keys, make a `spec/config.yml` file like this:

```yaml
public_key: 'PUBLIC KEY'
private_key: 'PRIVATE KEY'
```

## Contributing

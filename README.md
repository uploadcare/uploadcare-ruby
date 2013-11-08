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
pending

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


## Project
## Files list and pagination
## File
## Groups of files
## Testing

Run `bundle exec rspec`.

To run tests with your own keys, make a `spec/config.yml` file like this:

```yaml
public_key: 'PUBLIC KEY'
private_key: 'PRIVATE KEY'
```

## Contributing

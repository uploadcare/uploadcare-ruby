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


## Initalizations
Just create api object - and you good to go.

```ruby
@api = Uploadcare::Api.new(CONFIG)
```


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


## Basic usage
Using Uploadcare is pretty easy (which is the essence of the service itself).

Create the API object:

```ruby
@api = Uploadcare::Api.new(CONFIG)

```

Upload file

```ruby
@file_to_upload = File.open("your-file.png")

@uc_file = @api.upload_file(@file_to_upload)
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

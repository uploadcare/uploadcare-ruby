# Uploadcare::Ruby

Ruby wrapper for Uploadcare API

## Installation
Set your Uploadcare keys. You can do it either in config file, or through
environment variables `UPLOADCARE_PUBLIC_KEY` and `UPLOADCARE_SECRET_KEY`

```ruby
# config/uploadcare_settings.rb
module Uploadcare
  PUBLIC_KEY = ENV.fetch('UPLOADCARE_PUBLIC_KEY') || 'demopublickey'
  SECRET_KEY = ENV.fetch('UPLOADCARE_SECRET_KEY') || 'demoprivatekey'
end
```

Add this line to your application's Gemfile:

```ruby
gem 'uploadcare-ruby'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install uploadcare-ruby

## Usage

## Development
### Docs
https://uploadcare.com/docs/api_reference/
https://uploadcare.com/api-refs/rest-api/

### Architecture
Project uses [ApiStruct](https://github.com/rubygarage/api_struct) architecture.
#### uploadcare_settings.rb
This file lists used endpoints and their defaults
#### Client
This folder contains services that interact with API endpoints
#### Entity
This folder contains representations of entities existing in API
#### Headers
This folder contains anything related to unusual headers
#### Service
Objects that don't fit any pattern

-----

### Headers

## Contributing

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

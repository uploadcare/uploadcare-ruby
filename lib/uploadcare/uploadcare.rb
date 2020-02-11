# frozen_string_literal: true

require 'api_struct'
require 'dry-configurable'
require 'api_struct_settings'
require 'uploadcare_settings'
Gem.find_files('client/**/*.rb').each { |path| require path }
Gem.find_files('concerns/**/*.rb').each { |path| require path }
Gem.find_files('entity/**/*.rb').each { |path| require path }
Gem.find_files('header/**/*.rb').each { |path| require path }
Gem.find_files('service/**/*.rb').each { |path| require path }

# Ruby wrapper for Uploadcare API
# https://uploadcare.com/docs/api_reference
module Uploadcare
end

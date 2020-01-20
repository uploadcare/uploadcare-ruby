require 'api_struct'
require 'dry-configurable'
require 'uploadcare_settings'
Gem.find_files("client/**/*.rb").each { |path| require path }
Gem.find_files("entity/**/*.rb").each { |path| require path }
Gem.find_files("headers/**/*.rb").each { |path| require path }
Gem.find_files("service/**/*.rb").each { |path| require path }

module Uploadcare
end

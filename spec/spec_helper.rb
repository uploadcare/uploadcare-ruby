$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH << File.join(File.dirname(__FILE__))

require 'rubygems'
require 'pry'
require 'rspec'
require 'uploadcare'
require 'yaml'

CONFIG = Uploadcare.default_settings
UUID_REGEX = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

config_file = File.join(File.dirname(__FILE__), 'config.yml')
if File.exists?(config_file)
  CONFIG.update Hash[YAML.parse_file(config_file).to_ruby.map{|a, b| [a.to_sym, b]}]
end

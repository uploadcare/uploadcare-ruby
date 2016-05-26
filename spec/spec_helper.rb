$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH << File.join(File.dirname(__FILE__))

require 'rubygems'
require 'pry'
require 'rspec'
require 'uploadcare'
require 'yaml'
require 'vcr'

CONFIG = Uploadcare.default_settings
UUID_REGEX = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

API = Uploadcare::Api.new(CONFIG)
IMAGE_URL = "http://macaw.co/images/macaw-logo.png"

FILE1 = File.open(File.join(File.dirname(__FILE__), 'view.png'))
FILE2 = File.open(File.join(File.dirname(__FILE__), 'view2.jpg'))
FILES_ARY = [FILE1, FILE2]


config_file = File.join(File.dirname(__FILE__), 'config.yml')
if File.exists?(config_file)
  CONFIG.update Hash[YAML.parse_file(config_file).to_ruby.map{|a, b| [a.to_sym, b]}]
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
end

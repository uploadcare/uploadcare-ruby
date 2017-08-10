$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH << File.join(File.dirname(__FILE__))

require 'rubygems'
require 'pry'
require 'rspec'
require 'uploadcare'
require 'yaml'

CONFIG = Uploadcare.default_settings.merge!(
  public_key: ENV['UPLOADCARE_PUBLIC_KEY'] || 'demopublickey',
  private_key: ENV['UPLOADCARE_SECRET_KEY'] || 'demoprivatekey',
)
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

if CONFIG[:public_key] == 'demopublickey'
  RSpec.configure do |c|
    c.before(:example, :payed_feature){ skip "Unavailable for demo account" }
  end
end

Dir[File.join(File.dirname(__FILE__), 'shared/*.rb')].each{|path| require path}

def retry_if(error, retries=10, &block)
  block.call
rescue error
  raise if retries <= 0
  sleep 0.2
  retry_if(error, retries-1, &block)
end

def wait_until_ready(file)
  unless file.is_ready
    sleep 0.2
    file.load_data!
    wait_until_ready(file)
  end
end

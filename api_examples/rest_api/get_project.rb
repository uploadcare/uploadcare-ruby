require_relative '../../lib/uploadcare'
require 'dotenv/load'
Uploadcare.configuration.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', 'YOUR_PUBLIC_KEY')
Uploadcare.configuration.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', 'YOUR_SECRET_KEY')

project_info = Uploadcare::Project.show
puts project_info.inspect

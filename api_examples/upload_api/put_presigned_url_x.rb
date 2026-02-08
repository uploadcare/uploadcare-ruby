require_relative '../../lib/uploadcare'

Uploadcare.configuration.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', 'YOUR_PUBLIC_KEY')
Uploadcare.configuration.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', 'YOUR_SECRET_KEY')

File.open('spec/fixtures/kitten.jpeg', 'rb') do |source_file|
  Uploadcare::Uploader.upload(object: source_file, store: 'auto')
end

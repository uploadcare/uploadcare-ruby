require_relative '../../lib/uploadcare'
require 'dotenv/load'
Uploadcare.configuration.public_key = ENV.fetch('UPLOADCARE_PUBLIC_KEY', 'YOUR_PUBLIC_KEY')
Uploadcare.configuration.secret_key = ENV.fetch('UPLOADCARE_SECRET_KEY', 'YOUR_SECRET_KEY')

video_params = {
  uuid: ENV.fetch('UPLOADCARE_VIDEO_UUID', ENV.fetch('UPLOADCARE_FILE_UUID', '1bac376c-aa7e-4356-861b-dd2657b5bfd2')),
  format: :mp4,
  quality: :lighter
}
options = { store: true }
Uploadcare::VideoConverter.convert(params: video_params, options: options)

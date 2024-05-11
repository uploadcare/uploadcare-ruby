require 'uploadcare'
Uploadcare.config.public_key = 'YOUR_PUBLIC_KEY'
Uploadcare.config.secret_key = 'YOUR_SECRET_KEY'

video_params = {
  uuid: '1bac376c-aa7e-4356-861b-dd2657b5bfd2',
  format: :mp4,
  quality: :lighter
}
options = { store: true }
Uploadcare::VideoConverter.convert(video_params, options)

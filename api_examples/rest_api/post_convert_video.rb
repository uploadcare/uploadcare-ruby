require 'uploadcare'

# Configure API keys
Uploadcare.configure do |config|
  config.public_key = 'YOUR_PUBLIC_KEY'
  config.secret_key = 'YOUR_SECRET_KEY'
end

# Convert video with various options
uuid = 'VIDEO_UUID'

# Convert video
result = Uploadcare::VideoConverter.convert(
  [
    {
      uuid: uuid,
      format: 'mp4',           # Output format: mp4, webm, ogg
      quality: 'normal',       # Quality: normal, better, best, lighter, lightest
      size: {
        resize_mode: 'change_ratio',  # preserve_ratio, change_ratio, scale_crop, add_padding
        width: '1280',
        height: '720'
      },
      cut: {
        start_time: '0:0:0.0',  # Start time
        length: '0:1:0.0'       # Duration (or 'end')
      },
      thumbs: {
        N: 10,      # Number of thumbnails
        number: 1   # Specific thumbnail index
      }
    }
  ],
  store: true
)

token = result[:result].first[:token]
uuid_result = result[:result].first[:uuid]
thumbnails = result[:result].first[:thumbnails_group_uuid]

puts "Conversion started"
puts "Token: #{token}"
puts "Result UUID: #{uuid_result}"
puts "Thumbnails group: #{thumbnails}"

# Check status
status = Uploadcare::VideoConverter.status(token)
if status[:status] == 'finished'
  puts "Video conversion completed!"
end

#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/uploadcare'
require 'dotenv/load'

file_path = ARGV[0]

unless file_path && File.exist?(file_path)
  puts 'Usage: ruby upload_with_progress.rb <file_path>'
  puts 'Example: ruby upload_with_progress.rb large_video.mp4'
  puts
  puts 'Note: Progress tracking works best with files >= 10MB'
  exit 1
end

file_size = File.size(file_path)
file_size_mb = (file_size / 1024.0 / 1024.0).round(2)

puts "Uploading: #{file_path}"
puts "Size: #{file_size_mb} MB"
puts

if file_size < 10_000_000
  puts 'Note: File is < 10MB, so the upload may complete without multipart progress updates'
  puts
end

file = nil

begin
  client = Uploadcare::Client.new(
    public_key: ENV.fetch('UPLOADCARE_PUBLIC_KEY'),
    secret_key: ENV.fetch('UPLOADCARE_SECRET_KEY')
  )

  file = File.open(file_path, 'rb')
  start_time = Time.now

  result = client.uploads.upload(file, store: true) do |progress|
    uploaded_mb = (progress[:uploaded] / 1024.0 / 1024.0).round(2)
    total_mb = (progress[:total] / 1024.0 / 1024.0).round(2)
    percentage = ((progress[:uploaded].to_f / progress[:total]) * 100).round
    part = progress[:part]
    total_parts = progress[:total_parts]

    elapsed = Time.now - start_time
    speed_mbps = uploaded_mb / elapsed
    remaining_mb = total_mb - uploaded_mb
    eta_seconds = remaining_mb / speed_mbps if speed_mbps.positive?

    bar_length = 40
    filled = (bar_length * percentage / 100).to_i
    bar = ('#' * filled) + ('.' * (bar_length - filled))

    print "\r#{bar} #{percentage}% | "
    print "#{uploaded_mb}/#{total_mb} MB | "
    print "Part #{part}/#{total_parts} | "
    print "Speed: #{speed_mbps.round(2)} MB/s"
    print " | ETA: #{eta_seconds.to_i}s" if eta_seconds
    $stdout.flush
  end

  elapsed = Time.now - start_time

  puts
  puts
  puts '✓ Upload successful!'
  puts
  puts "UUID: #{result.uuid}"
  puts "Filename: #{result.original_filename}"
  puts "Total time: #{elapsed.round(2)} seconds"
  puts "Average speed: #{(file_size_mb / elapsed).round(2)} MB/s"
  puts
  puts "CDN URL: #{result.cdn_url}"
rescue StandardError => e
  puts
  puts "✗ Upload failed: #{e.message}"
  exit 1
ensure
  file&.close
end

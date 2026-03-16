#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/uploadcare'
require 'dotenv/load'

file_path = ARGV[0]
threads = (ARGV[1] || 4).to_i

unless file_path && File.exist?(file_path)
  puts 'Usage: ruby large_file_upload.rb <file_path> [threads]'
  puts 'Example: ruby large_file_upload.rb large_video.mp4 4'
  puts
  puts 'threads: Number of parallel upload threads (default: 4)'
  exit 1
end

file_size = File.size(file_path)
file_size_mb = (file_size / 1024.0 / 1024.0).round(2)

if file_size < 10_000_000
  puts 'Warning: File is < 10MB. Multipart upload is recommended for files >= 10MB'
  puts 'The upload will still work but may use base upload instead.'
  puts
end

puts 'Large File Upload'
puts '=' * 50
puts "File: #{file_path}"
puts "Size: #{file_size_mb} MB"
puts "Threads: #{threads}"
puts

begin
  client = Uploadcare::Client.new(
    public_key: ENV.fetch('UPLOADCARE_PUBLIC_KEY'),
    secret_key: ENV.fetch('UPLOADCARE_SECRET_KEY')
  )

  start_time = Time.now
  result = nil

  File.open(file_path, 'rb') do |file|
    result = client.uploads.multipart_upload(
      file: file,
      store: true,
      threads: threads,
      metadata: {
        source: 'large_file_example',
        upload_method: 'multipart'
      }
    ) do |progress|
      uploaded_mb = (progress[:uploaded] / 1024.0 / 1024.0).round(2)
      total_mb = (progress[:total] / 1024.0 / 1024.0).round(2)
      percentage = ((progress[:uploaded].to_f / progress[:total]) * 100).round
      part = progress[:part]
      total_parts = progress[:total_parts]

      bar_length = 30
      filled = (bar_length * percentage / 100).to_i
      bar = ('#' * filled) + ('.' * (bar_length - filled))

      print "\r#{bar} #{percentage}% | Part #{part}/#{total_parts} | #{uploaded_mb}/#{total_mb} MB"
      $stdout.flush
    end
  end

  elapsed = Time.now - start_time

  puts
  puts
  puts '✓ Upload successful!'
  puts
  puts 'Upload Details:'
  puts '-' * 50
  puts "UUID: #{result.uuid}"
  puts "Size: #{file_size_mb} MB"
  puts "Time: #{elapsed.round(2)} seconds"
  puts "Speed: #{(file_size_mb / elapsed).round(2)} MB/s"
  puts "Threads: #{threads}"
  puts 'Method: Multipart upload'
  puts
  puts "CDN URL: #{result.cdn_url}"
rescue StandardError => e
  puts
  puts "✗ Upload failed: #{e.message}"
  exit 1
end

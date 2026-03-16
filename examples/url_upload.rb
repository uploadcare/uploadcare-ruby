#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/uploadcare'
require 'dotenv/load'

url = ARGV[0]

unless url&.match?(%r{^https?://})
  puts 'Usage: ruby url_upload.rb <url>'
  puts 'Example: ruby url_upload.rb https://example.com/image.jpg'
  exit 1
end

puts 'URL Upload'
puts '=' * 50
puts "URL: #{url}"
puts

begin
  client = Uploadcare::Client.new(
    public_key: ENV.fetch('UPLOADCARE_PUBLIC_KEY'),
    secret_key: ENV.fetch('UPLOADCARE_SECRET_KEY')
  )

  puts 'Starting upload...'
  result = client.files.upload_from_url(url, store: true)

  puts '✓ Upload successful!'
  puts
  puts "UUID: #{result.uuid}"
  puts "Filename: #{result.original_filename}"
  puts "Size: #{(result.size / 1024.0).round(2)} KB"
  puts "MIME type: #{result.mime_type}"
  puts
  puts "CDN URL: #{result.cdn_url}"
  puts
  puts 'Advanced Usage:'
  puts
  puts '# Async mode (returns immediately with token):'
  puts 'client = Uploadcare::Client.new(public_key: "...", secret_key: "...")'
  puts "response = client.uploads.upload_from_url(url: '#{url}', async: true)"
  puts "token = response['token']"
  puts
  puts '# Check status later:'
  puts 'status = client.uploads.upload_from_url_status(token: token)'
  puts "puts status['status']"
rescue StandardError => e
  puts "✗ Upload failed: #{e.message}"
  puts
  puts 'Common issues:'
  puts '- URL must be publicly accessible'
  puts '- URL must return a valid file'
  puts '- Some file types may not be supported'
  exit 1
end

#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/uploadcare'
require 'dotenv/load'

file_path = ARGV[0]

unless file_path && File.exist?(file_path)
  puts 'Usage: ruby file_tags.rb <file_path>'
  puts 'Example: ruby file_tags.rb photo.jpg'
  exit 1
end

client = Uploadcare::Client.new(
  public_key: ENV.fetch('UPLOADCARE_PUBLIC_KEY'),
  secret_key: ENV.fetch('UPLOADCARE_SECRET_KEY')
)

file = File.open(file_path, 'rb') do |io|
  client.files.upload(io, store: true, tags: %w[example draft])
end

puts "Uploaded #{file.uuid} with tags: #{client.file_tags.list(uuid: file.uuid).join(', ')}"

change = client.file_tags.replace(uuid: file.uuid, tags: %w[example approved])
puts "Replaced tags: #{change.tags.join(', ')}"

change = client.file_tags.update(uuid: file.uuid, add: ['featured'], delete: ['example'])
puts "Updated tags: #{change.tags.join(', ')}"

#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/uploadcare'
require 'dotenv/load'

query = ARGV.join(' ')

if query.length < 4
  puts 'Usage: ruby file_search.rb <query of at least four characters>'
  puts 'Example: ruby file_search.rb invoice'
  exit 1
end

begin
  client = Uploadcare::Client.new(
    public_key: ENV.fetch('UPLOADCARE_PUBLIC_KEY'),
    secret_key: ENV.fetch('UPLOADCARE_SECRET_KEY')
  )

  results = client.files.search(query: query, sort: ['-datetime_uploaded'], limit: 20)

  puts "Found #{results.total} files"
  results.each do |file|
    puts [file.uuid, file.original_filename, file.highlight].compact.join(' | ')
  end

  next_page = results.next_page
  puts "Next page contains #{next_page.length} files" if next_page
rescue StandardError => e
  warn "File search example failed: #{e.message}"
  exit 1
end

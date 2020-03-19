# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:all) do
    generate_big_file
  end
end

# Generate 10mb file which is needed for some tests (Multipart upload).
# This file isn't included in main repository to avoid bloat.
def generate_big_file
  return unless File.file?('spec/fixtures/big.jpeg')

  FileUtils.cp('spec/fixtures/kitten.jpeg', 'spec/fixtures/big.jpeg')
  source_file = File.open('spec/fixtures/kitten.jpeg')
  destination = File.open('spec/fixtures/big.jpeg', 'w')
  destination.write(source_file.read)
  destination.write('a' * 10 * 1024 * 1024)
end

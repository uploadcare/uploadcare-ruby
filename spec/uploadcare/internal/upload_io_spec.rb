# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'stringio'

RSpec.describe Uploadcare::Internal::UploadIo do
  describe '.wrap' do
    it 'returns a wrapper around a path-backed file without copying it' do
      file = Tempfile.new(['upload-io', '.jpg'])
      file.write('abc')
      file.rewind

      wrapped = described_class.wrap(file)

      expect(wrapped.path).to eq(file.path)
      expect(wrapped.original_filename).to match(/upload-io.*\.jpg/)
      expect(wrapped.size).to eq(3)

      wrapped.close!
      expect(File.exist?(file.path)).to eq(true)
      file.close!
    end

    it 'normalizes a non-path IO object into a temp file' do
      wrapped = described_class.wrap(StringIO.new('stream-data'))

      expect(File.exist?(wrapped.path)).to eq(true)
      expect(wrapped.original_filename).to eq('upload.bin')
      expect(wrapped.size).to eq(11)

      path = wrapped.path
      wrapped.close!
      expect(File.exist?(path)).to eq(false)
    end

    it 'preserves original_filename when available on the source object' do
      io = StringIO.new('abc')
      io.define_singleton_method(:original_filename) { 'avatar.png' }

      wrapped = described_class.wrap(io)

      expect(wrapped.original_filename).to eq('avatar.png')
      expect(File.extname(wrapped.path)).to eq('.png')
      wrapped.close!
    end

    it 'raises for unreadable input' do
      expect do
        described_class.wrap('not-io')
      end.to raise_error(ArgumentError, /readable IO/)
    end

    it 'does not treat directories as path-backed files' do
      Dir.mktmpdir do |directory|
        source = StringIO.new('stream-data')
        source.define_singleton_method(:path) { directory }

        wrapped = described_class.wrap(source, filename: 'directory.txt')

        expect(File.file?(wrapped.path)).to eq(true)
        expect(wrapped.original_filename).to eq('directory.txt')
        wrapped.close!
      end
    end
  end
end

# frozen_string_literal: true

require 'tempfile'

class Uploadcare::Internal::UploadIo
  DEFAULT_FILENAME = 'upload.bin'

  attr_reader :io, :original_filename

  def self.wrap(source, filename: nil)
    raise ArgumentError, 'file must be a readable IO object' unless source.respond_to?(:read)

    if path_backed?(source)
      new(source, original_filename: filename || extract_filename(source), cleanup: false)
    else
      wrap_stream(source, filename: filename || extract_filename(source))
    end
  end

  def self.path_backed?(source)
    source.respond_to?(:path) && source.path && ::File.exist?(source.path)
  end

  def self.extract_filename(source)
    if source.respond_to?(:original_filename) && source.original_filename && !source.original_filename.empty?
      source.original_filename
    elsif path_backed?(source)
      ::File.basename(source.path)
    else
      DEFAULT_FILENAME
    end
  end

  def self.wrap_stream(source, filename:)
    extension = ::File.extname(filename.to_s)
    tempfile = Tempfile.new(['uploadcare-upload', extension.empty? ? '.bin' : extension])
    tempfile.binmode

    source.rewind if source.respond_to?(:rewind)
    IO.copy_stream(source, tempfile)
    tempfile.rewind
    source.rewind if source.respond_to?(:rewind)

    new(tempfile, original_filename: filename, cleanup: true)
  end

  def initialize(io, original_filename:, cleanup:)
    @io = io
    @original_filename = original_filename
    @cleanup = cleanup
  end

  def path
    io.path
  end

  def size
    return io.size if io.respond_to?(:size)

    ::File.size(path)
  end

  def read(*args)
    io.read(*args)
  end

  def seek(*args)
    io.seek(*args)
  end

  def rewind
    io.rewind
  end

  def close!
    return unless @cleanup

    io.close!
  end
end

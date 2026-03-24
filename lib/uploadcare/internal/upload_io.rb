# frozen_string_literal: true

require 'tempfile'

# Wraps upload inputs so multipart and direct uploads can treat files and streams uniformly.
class Uploadcare::Internal::UploadIo
  # Fallback filename used when the source object does not expose one.
  DEFAULT_FILENAME = 'upload.bin'

  attr_reader :io, :original_filename

  # Wrap a readable source into a unified upload object.
  #
  # @param source [IO]
  # @param filename [String, nil]
  # @return [Uploadcare::Internal::UploadIo]
  def self.wrap(source, filename: nil)
    raise ArgumentError, 'file must be a readable IO object' unless source.respond_to?(:read)

    if path_backed?(source)
      new(source, original_filename: filename || extract_filename(source), cleanup: false)
    else
      wrap_stream(source, filename: filename || extract_filename(source))
    end
  end

  # @param source [IO]
  # @return [Boolean]
  def self.path_backed?(source)
    source.respond_to?(:path) &&
      source.path &&
      ::File.file?(source.path) &&
      ::File.readable?(source.path)
  end

  # @param source [IO]
  # @return [String]
  def self.extract_filename(source)
    if source.respond_to?(:original_filename) && source.original_filename && !source.original_filename.empty?
      source.original_filename
    elsif path_backed?(source)
      ::File.basename(source.path)
    else
      DEFAULT_FILENAME
    end
  end

  # Materialize a non-path-backed stream into a tempfile.
  #
  # @param source [IO]
  # @param filename [String]
  # @return [Uploadcare::Internal::UploadIo]
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

  # @param io [IO]
  # @param original_filename [String]
  # @param cleanup [Boolean]
  def initialize(io, original_filename:, cleanup:)
    @io = io
    @original_filename = original_filename
    @cleanup = cleanup
  end

  # @return [String]
  def path
    io.path
  end

  # @return [Integer]
  def size
    return io.size if io.respond_to?(:size)

    ::File.size(path)
  end

  # @return [String, nil]
  def read(*args)
    io.read(*args)
  end

  # @return [Integer]
  def seek(*args)
    io.seek(*args)
  end

  # @return [void]
  def rewind
    io.rewind
  end

  # Close and unlink the wrapped tempfile when cleanup is enabled.
  #
  # @return [void]
  def close!
    return unless @cleanup

    io.close!
  end
end

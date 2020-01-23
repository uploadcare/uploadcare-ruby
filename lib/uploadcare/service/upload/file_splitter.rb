# This class splits files into chunks of certain size, except the last one, which can be smaller.
# Needed for multipart upload

module Uploadcare
  module Upload
    class FileSplitter
      def call(file, size)
        # Array.new(((string.length + size - 1) / size)) { |i| string.byteslice(i * size, size) }
      end
    end
  end
end

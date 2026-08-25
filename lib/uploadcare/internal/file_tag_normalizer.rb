# frozen_string_literal: true

# Normalizes and validates file tags before sending them to Uploadcare.
class Uploadcare::Internal::FileTagNormalizer
  MAX_LENGTH = 100
  MAX_COUNT = 50
  VALID_PATTERN = /\A[a-z0-9._-]+\z/

  class << self
    # Normalize a list of file tags.
    #
    # Tags are stripped, lowercased, and deduplicated while preserving their
    # first-seen order.
    #
    # @param tags [Array<String>]
    # @param max_count [Integer, nil] Maximum number of tags; nil disables the limit
    # @return [Array<String>]
    # @raise [ArgumentError] if a tag is invalid
    def call(tags, max_count: MAX_COUNT)
      raise ArgumentError, 'tags must be an array of strings' unless tags.is_a?(Array)

      normalized = normalize(tags)
      validate_count(normalized, max_count)
      normalized
    end

    private

    def normalize(tags)
      seen = {}

      tags.each_with_object([]) do |tag, result|
        raise ArgumentError, 'tags must be an array of strings' unless tag.is_a?(String)

        value = tag.strip.downcase
        next if value.empty?

        validate_tag(value)
        next if seen[value]

        seen[value] = true
        result << value
      end
    end

    def validate_tag(tag)
      if tag.length > MAX_LENGTH
        raise ArgumentError, "tag is too long: #{tag.length} characters (maximum #{MAX_LENGTH})"
      end
      return if VALID_PATTERN.match?(tag)

      raise ArgumentError,
            'tag contains invalid characters; allowed: Latin letters, digits, hyphen, underscore, dot'
    end

    def validate_count(tags, max_count)
      return if max_count.nil? || max_count.zero? || tags.length <= max_count

      raise ArgumentError, "too many tags: #{tags.length} (maximum #{max_count})"
    end
  end
end

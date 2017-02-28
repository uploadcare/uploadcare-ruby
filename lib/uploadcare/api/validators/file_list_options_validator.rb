module Uploadcare
  module Validators

    class FileListOptionsValidator
      SUPPORTED_KEYS = [:from, :ordering, :limit, :stored, :removed]

      def initialize(options)
        @options = options
      end

      def validate
        check_for_unsupported_keys(@options)

        validate_limit(@options[:limit])
        validate_stored(@options[:stored])
        validate_removed(@options[:removed])
        validate_ordering_and_from(@options[:ordering], @options[:from])
      end

      private

      def check_for_unsupported_keys(options)
        unsupported_keys = options.keys.reject{|k,_| SUPPORTED_KEYS.include?(k)}
        error("Unknown options: #{unsupported_keys}") if unsupported_keys.any?
      end

      def validate_ordering_and_from(ordering, from)
        case ordering
        when nil, /^-?datetime_uploaded$/
          validate_from_as_date(from)
        when /^-?size$/
          validate_from_as_size(from)
        else
          error("Unknown value for :ordering option: #{ordering.inspect}")
        end
      end

      def validate_from_as_date(from)
        return if from.nil? || from.to_s =~ /^\d{4}-\d{2}-\d{2}T\d{2}.*/
        error(":from value should be a DateTime or an iso8601 string when "\
          "ordering is `datetime_uploaded` or `-datetime_uploaded`, "\
          "#{from.inspect} given")
      end

      def validate_from_as_size(from)
        return if from.nil? || (from.is_a?(Integer) && from >= 0)
        error(":from value should be a positive integer when ordering is "\
          "`size` or `-size`, #{from.inspect} given")
      end

      def validate_limit(limit)
        return if limit.nil? || (limit.is_a?(Integer) && (1..1000).include?(limit))
        error(":limit should be a positive integer from 1 to 1000, "\
          "#{limit.inspect} given")
      end

      def validate_stored(stored)
        return if [nil, true, false].include?(stored)
        error(":stored can be true or false, #{stored.inspect} given")
      end

      def validate_removed(removed)
        return if [nil, true, false].include?(removed)
        error(":removed can be true or false, #{removed.inspect} given")
      end

      def error(message)
        raise ArgumentError, message
      end
    end

  end
end

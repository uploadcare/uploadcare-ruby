module Uploadcare
  module Validators

    class GroupListOptionsValidator
      SUPPORTED_KEYS = [:from, :ordering, :limit]

      def initialize(options)
        @options = options
      end

      def validate
        check_for_unsupported_keys(@options)

        validate_limit(@options[:limit])
        validate_ordering(@options[:ordering])
        validate_from(@options[:from])
      end

      private

      def check_for_unsupported_keys(options)
        unsupported_keys = options.keys.reject{|k,_| SUPPORTED_KEYS.include?(k)}
        error("Unknown options: #{unsupported_keys}") if unsupported_keys.any?
      end

      def validate_ordering(ordering)
        return if !ordering || ordering =~ /^-?datetime_created$/
        error("Unknown value for :ordering option: #{ordering.inspect}")
      end

      def validate_from(from)
        return if from.nil? || from.to_s =~ /^\d{4}-\d{2}-\d{2}T\d{2}.*/
        error(":from value should be a DateTime or an iso8601 string, "\
          "#{from.inspect} given")
      end

      def validate_limit(limit)
        return if limit.nil? || (limit.is_a?(Integer) && (1..1000).include?(limit))
        error(":limit should be a positive integer from 1 to 1000, "\
          "#{limit.inspect} given")
      end

      def error(message)
        raise ArgumentError, message
      end
    end

  end
end

# frozen_string_literal: true

require 'param/conversion/video/validators/base'

module Uploadcare
  module Param
    module Conversion
      module Video
        module Validators
          class Uuid < Base
            UUID_REGEX = /\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b/.freeze

            class << self
              def call(uuid:)
                validate_uuid!(uuid)
              end

              private

              def validate_uuid!(uuid)
                return uuid if uuid.is_a?(String) && uuid.match?(UUID_REGEX)

                raise_error(message: "The specified :uuid is invalid. Must match the regex: #{UUID_REGEX}")
              end
            end
          end
        end
      end
    end
  end
end

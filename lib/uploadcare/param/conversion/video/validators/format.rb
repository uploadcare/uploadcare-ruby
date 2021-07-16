# frozen_string_literal: true

require 'param/conversion/video/validators/base'

module Uploadcare
  module Param
    module Conversion
      module Video
        module Validators
          class Format < Base
            class << self
              def call(format: 'mp4')
                validate_format!(format)
              end

              private

              def validate_format!(format)
                formats = self::SUPPORTED_OPTIONS.formats
                return format if formats.include?(format)

                raise_error(
                  message: "The specified :format is unsupported. Must be one of: #{formats.join(', ')}"
                )
              end
            end
          end
        end
      end
    end
  end
end

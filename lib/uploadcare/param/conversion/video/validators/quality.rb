# frozen_string_literal: true

require 'param/conversion/video/validators/base'

module Uploadcare
  module Param
    module Conversion
      module Video
        module Validators
          class Quality < Base
            class << self
              def call(quality: 'normal')
                validate_quality!(quality)
              end

              private

              def validate_quality!(quality)
                qualities = self::SUPPORTED_OPTIONS.qualities
                return quality if qualities.include?(quality)

                raise_error(
                  message: "The specified :quality is unsupported. Must be one of: #{qualities.join(', ')}"
                )
              end
            end
          end
        end
      end
    end
  end
end

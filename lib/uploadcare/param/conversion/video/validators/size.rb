# frozen_string_literal: true

require 'param/conversion/video/validators/base'

module Uploadcare
  module Param
    module Conversion
      module Video
        module Validators
          class Size < Base
            class << self
              def call(resize_mode: 'preserve_ratio', width: nil, height: nil)
                {
                  resize_mode: validate_resize_mode!(resize_mode),
                  **validate_dimensions!(width, height)
                }
              end

              private

              def validate_resize_mode!(resize_mode)
                resize_modes = self::SUPPORTED_OPTIONS.resize_modes
                return resize_mode if resize_modes.include?(resize_mode)

                raise_error(
                  message: "The specified :resize_mode is unsupported. Must be one of: #{resize_modes.join(', ')}"
                )
              end

              def validate_dimensions!(width, height)
                validate_dimensions_presence!(width, height)
                {
                  width: width,
                  height: height
                }.compact.map { |param_name, value| [param_name, validate_dimension!(param_name, value)] }.to_h
              end

              def validate_dimensions_presence!(width, height)
                return if !width.nil? || !height.nil?

                raise_error(message: "Height and width can't be both blank. Please, specify width, height or both")
              end

              def validate_dimension!(param_name, value)
                int_value = value.to_i if value.respond_to?(:to_i)
                # The value you specify for any of the dimensions should be a non-zero integer divisible by 4
                return int_value if int_value&.positive? && (int_value % 4 == 0)

                raise_error(message: "The parameter :#{param_name} is invalid. Must be non-zero integer divisible by 4")
              end
            end
          end
        end
      end
    end
  end
end

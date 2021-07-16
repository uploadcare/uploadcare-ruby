# frozen_string_literal: true

require 'param/conversion/video/validators/base'

module Uploadcare
  module Param
    module Conversion
      module Video
        module Validators
          class Cut < Base
            VALID_REGEX = [
              /\A\d{1,3}:[0-5]?[0-9]:[0-5]?[0-9]\.\d{,3}\z/,
              /\A[0-5]?[0-9]:[0-5]?[0-9]\.\d{,3}\z/,
              /\A[0-5]?[0-9]\.\d{,3}\z/,
              /\A\d+(\.\d{,3})?\z/,
              /\A\d{1,50}\z/
            ].freeze

            class << self
              def call(start_time: , length:)
                { start_time: validate_start_time!(start_time), length: validate_length!(length) }
              end

              private

              def validate_start_time!(start_time)
                return start_time if time_valid?(start_time)

                raise_error(message: error_message_for('start_time'))
              end

              def time_valid?(time)
                string_time = time.to_s if time.respond_to?(:to_s)
                VALID_REGEX.any? { |regex| string_time&.match?(regex) }
              end

              def validate_length!(length)
                return length if length == 'end' || time_valid?(length)

                raise_error(message: error_message_for('length'))
              end

              def error_message_for(param_name)
                "The specified cut :#{param_name} is invalid. " \
                "Please, check https://uploadcare.com/docs/transformations/video-encoding/#operation-cut " \
                "for more information"
              end
            end
          end
        end
      end
    end
  end
end

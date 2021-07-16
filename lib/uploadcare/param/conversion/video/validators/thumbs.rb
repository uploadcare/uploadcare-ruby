# frozen_string_literal: true

require 'param/conversion/video/validators/base'

module Uploadcare
  module Param
    module Conversion
      module Video
        module Validators
          class Thumbs < Base
            VALID_N_RANGE = 1..50

            class << self
              def call(n: 1, number: 0)
                n = validate_n!(n)
                { N: n, number: validate_number!(n.to_i, number) }
              end

              private

              def validate_n!(n)
                return n if n.respond_to?(:to_i) && VALID_N_RANGE.cover?(n.to_i)

                raise_error(message: error_message_for('N', VALID_N_RANGE))
              end

              def validate_number!(n, number)
                valid_range = 0..(n-1)
                return number if number.respond_to?(:to_i) && valid_range.cover?(number.to_i)

                raise_error(message: error_message_for('number', valid_range))
              end

              def error_message_for(param_name, range)
                "The specified :#{param_name} is invalid. " \
                "Must be integer in range #{range.first} - #{range.last}"
              end
            end
          end
        end
      end
    end
  end
end

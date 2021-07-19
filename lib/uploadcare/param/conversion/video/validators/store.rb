# frozen_string_literal: true

require 'param/conversion/video/validators/base'

module Uploadcare
  module Param
    module Conversion
      module Video
        module Validators
          class Store < Base
            VALID_VALUES = {
              nil => nil,
              true => '1',
              false => '0'
            }.freeze

            class << self
              def call(store: nil)
                validate_store!(store)
              end

              private

              def validate_store!(store)
                return VALID_VALUES[store] if VALID_VALUES.keys.include?(store)

                raise_error(
                  message: 'The specified :store is invalid. ' \
                           "Must be nil or one of: #{VALID_VALUES.keys.compact.join(', ')}"
                )
              end
            end
          end
        end
      end
    end
  end
end

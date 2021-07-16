# frozen_string_literal: true

require 'yaml'
require 'exception/validation_error'

module Uploadcare
  module Param
    module Conversion
      module Video
        module Validators
          class Base
            SUPPORTED_OPTIONS = JSON.parse(
              YAML::load_file(File.join(__dir__, '..', 'supported_options.yml')).to_json, object_class: OpenStruct
            )

            class << self

              private

              def raise_error(message: nil, error_class: Uploadcare::Exception::ValidationError)
                raise error_class.new(message)
              end
            end
          end
        end
      end
    end
  end
end

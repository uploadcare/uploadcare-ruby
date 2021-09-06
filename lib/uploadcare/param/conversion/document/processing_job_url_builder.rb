# frozen_string_literal: true

module Uploadcare
  module Param
    module Conversion
      module Document
        class ProcessingJobUrlBuilder
          class << self
            def call(uuid:, format: nil, page: nil)
              [
                uuid_part(uuid),
                format_part(format),
                page_part(page)
              ].compact.join('-')
            end

            private

            def uuid_part(uuid)
              "#{uuid}/document/"
            end

            def format_part(format)
              return if format.nil?

              "/format/#{format}/"
            end

            def page_part(page)
              return if page.nil?

              "/page/#{page}/"
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Uploadcare
  module Param
    module Conversion
      module Video
        class ProcessingJobUrlBuilder
          class << self
            def call(uuid:, size: {}, quality: nil, format: nil, cut: {}, thumbs: {})
              [
                uuid_part(uuid),
                size_part(size),
                quality_part(quality),
                format_part(format),
                cut_part(cut),
                thumbs_part(thumbs)
              ].compact.join('-')
            end

            private

            def uuid_part(uuid)
              "#{uuid}/video/"
            end

            def size_part(size)
              return if size.empty?

              dimensions = "#{size[:width]}x#{size[:height]}"
              resize_mode = "#{size[:resize_mode]}"
              "/size/#{dimensions}/#{resize_mode}/".squeeze('/')
            end

            def quality_part(quality)
              return if quality.nil?

              "/quality/#{quality}/"
            end

            def format_part(format)
              return if format.nil?

              "/format/#{format}/"
            end

            def cut_part(cut)
              return if cut.empty?

              "/cut/#{cut[:start_time]}/#{cut[:length]}/"
            end

            def thumbs_part(thumbs)
              return if thumbs.empty?

              "/thumbs~#{thumbs[:N]}/#{thumbs[:number]}/".squeeze('/')
            end
          end
        end
      end
    end
  end
end

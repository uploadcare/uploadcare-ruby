# frozen_string_literal: true

module Uploadcare
  module Concerns
    # Adds transformation capabilities to resources
    module Transformable
      extend ActiveSupport::Concern if defined?(ActiveSupport)

      # Chain transformations fluently
      def resize(width, height = nil)
        add_transformation(:resize, "#{width}x#{height || width}")
        self
      end

      def crop(dimensions, alignment = 'center')
        add_transformation(:crop, "#{dimensions}/#{alignment}")
        self
      end

      def quality(value)
        add_transformation(:quality, value)
        self
      end

      def format(type)
        add_transformation(:format, type)
        self
      end

      def grayscale
        add_transformation(:grayscale, true)
        self
      end

      def blur(strength = nil)
        add_transformation(:blur, strength)
        self
      end

      def rotate(angle)
        add_transformation(:rotate, angle)
        self
      end

      def flip
        add_transformation(:flip, true)
        self
      end

      def mirror
        add_transformation(:mirror, true)
        self
      end

      def smart_resize(width, height = nil)
        add_transformation(:smart_resize, "#{width}x#{height || width}")
        self
      end

      def preview(width = nil, height = nil)
        add_transformation(:preview, "#{width}x#{height}") if width
        self
      end

      def build_url
        base_url = original_file_url || cdn_url
        return base_url if @transformations.blank?

        transformations = @transformations.map do |key, value|
          next if value.nil? || value == false
          value == true ? "-/#{key}/" : "-/#{key}/#{value}/"
        end.compact.join

        "#{base_url}#{transformations}"
      end

      def to_url
        build_url
      end

      private

      def add_transformation(key, value)
        @transformations ||= {}
        @transformations[key] = value
        self
      end
    end
  end
end
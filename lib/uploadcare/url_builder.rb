# frozen_string_literal: true

module Uploadcare
  class UrlBuilder
    attr_reader :base_url, :operations

    def initialize(source, config = Uploadcare.configuration)
      @config = config
      @base_url = construct_base_url(source)
      @operations = []
    end

    # Image resize operations
    def resize(width, height = nil)
      if height.nil?
        add_operation("resize/#{width}")
      else
        add_operation("resize/#{width}x#{height}")
      end
    end

    def resize_width(width)
      add_operation("resize/#{width}x")
    end

    def resize_height(height)
      add_operation("resize/x#{height}")
    end

    def scale_crop(width, height, options = {})
      operation = "scale_crop/#{width}x#{height}"
      operation += "/#{options[:type]}" if options[:type]
      operation += "/#{options[:offset_x]},#{options[:offset_y]}" if options[:offset_x] && options[:offset_y]
      add_operation(operation)
    end

    def smart_resize(width, height)
      add_operation("scale_crop/#{width}x#{height}/smart")
    end

    # Crop operations
    def crop(width, height, options = {})
      operation = "crop/#{width}x#{height}"
      operation += "/#{options[:offset_x]},#{options[:offset_y]}" if options[:offset_x] && options[:offset_y]
      add_operation(operation)
    end

    def crop_faces(ratio = nil)
      operation = 'crop/faces'
      operation += "/#{ratio}" if ratio
      add_operation(operation)
    end

    def crop_objects(ratio = nil)
      operation = 'crop/objects'
      operation += "/#{ratio}" if ratio
      add_operation(operation)
    end

    # Format operations
    def format(fmt)
      add_operation("format/#{fmt}")
    end

    def quality(value)
      add_operation("quality/#{value}")
    end

    def progressive(value = 'yes')
      add_operation("progressive/#{value}")
    end

    # Effects and filters
    def grayscale
      add_operation('grayscale')
    end

    def invert
      add_operation('invert')
    end

    def flip
      add_operation('flip')
    end

    def mirror
      add_operation('mirror')
    end

    def rotate(angle)
      add_operation("rotate/#{angle}")
    end

    def blur(strength = nil)
      operation = 'blur'
      operation += "/#{strength}" if strength
      add_operation(operation)
    end

    def sharpen(strength = nil)
      operation = 'sharpen'
      operation += "/#{strength}" if strength
      add_operation(operation)
    end

    def enhance(strength = nil)
      operation = 'enhance'
      operation += "/#{strength}" if strength
      add_operation(operation)
    end

    def brightness(value)
      add_operation("brightness/#{value}")
    end

    def exposure(value)
      add_operation("exposure/#{value}")
    end

    def gamma(value)
      add_operation("gamma/#{value}")
    end

    def contrast(value)
      add_operation("contrast/#{value}")
    end

    def saturation(value)
      add_operation("saturation/#{value}")
    end

    def vibrance(value)
      add_operation("vibrance/#{value}")
    end

    def warmth(value)
      add_operation("warmth/#{value}")
    end

    # Color adjustments
    def max_icc_size(value)
      add_operation("max_icc_size/#{value}")
    end

    def srgb(value = 'true')
      add_operation("srgb/#{value}")
    end

    # Face detection
    def detect_faces
      add_operation('detect_faces')
    end

    # Video operations
    def video_thumbs(time)
      add_operation("video/thumbs~#{time}")
    end

    # Preview operation
    def preview(width = nil, height = nil)
      operation = 'preview'
      operation += "/#{width}x#{height}" if width || height
      add_operation(operation)
    end

    # Filename
    def filename(name)
      @filename = name
      self
    end

    # Build the final URL
    def url
      return @base_url if @operations.empty?

      url_parts = [@base_url]
      url_parts << @operations.map { |op| "-/#{op}/" }.join
      url_parts << @filename if @filename

      url_parts.join
    end

    alias to_s url
    alias to_url url

    # Chain operations
    def add_operation(operation)
      @operations << operation
      self
    end

    private

    def construct_base_url(source)
      case source
      when Uploadcare::File
        source.cdn_url.chomp('/')
      when String
        if source.start_with?('http://', 'https://')
          source.chomp('/')
        else
          # Assume it's a UUID
          "#{@config.cdn_url_base}#{source}"
        end
      else
        raise ArgumentError, 'Invalid source type. Expected Uploadcare::File or String (UUID/URL)'
      end
    end
  end
end

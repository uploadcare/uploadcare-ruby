# frozen_string_literal: true

require 'api_struct'
require 'param/user_agent'
require 'uploadcare/concern/error_handler'
require 'uploadcare/concern/throttle_handler'
require 'mimemagic'

module Uploadcare
  module Client
    # @abstract
    #
    # Headers and helper methods for clients working with upload API
    # @see https://uploadcare.com/docs/api_reference/upload/
    class UploadClient < ApiStruct::Client
      include Concerns::ErrorHandler
      include Concerns::ThrottleHandler
      include Exception

      def api_root
        Uploadcare.config.upload_api_root
      end

      def headers
        {
          'User-Agent': Uploadcare::Param::UserAgent.call
        }
      end

      private

      def form_data_for(file)
        filename = file.original_filename if file.respond_to?(:original_filename)
        mime_type = MimeMagic.by_magic(file).type
        options = { filename: filename, content_type: mime_type }.compact
        HTTP::FormData::File.new(file, options)
      end

      def default_params
        {}
      end
    end
  end
end

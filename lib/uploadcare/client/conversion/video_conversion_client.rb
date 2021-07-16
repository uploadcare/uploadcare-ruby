# frozen_string_literal: true

Gem.find_files('param/conversion/video/validators/*.rb').each { |path| require path }
require_relative '../rest_client'
require 'param/conversion/video/processing_job_url_builder'
require 'exception/validation_error'

module Uploadcare
  module Client
    module Conversion
      # This is client for video conversion
      #
      # @see https://uploadcare.com/api-refs/rest-api/v0.6.0/#operation/videoConvert
      class VideoConversionClient < RestClient
          VALIDATORS_NAMESPASE = "Uploadcare::Param::Conversion::Video::Validators".freeze

        def convert_many(arr, **options)
          body = build_body_for_many(arr, options)
          post(uri: '/convert/video/', content: body)
        end

        def headers
          {
            'Content-type': 'application/json',
            'Accept': 'application/vnd.uploadcare-v0.6+json',
            'User-Agent': Uploadcare::Param::UserAgent.call
          }
        end

        private

        # Prepares body for convert_many method
        def build_body_for_many(arr, options)
          check_array_param(arr)
          {
            "paths": arr.map do |params|
              Uploadcare::Param::Conversion::Video::ProcessingJobUrlBuilder.call(
                **{
                  uuid: validator_for('Uuid')&.call(uuid: params[:uuid]),
                  quality: string_params('Quality', 'quality', params[:quality]),
                  format: string_params('Format', 'format', params[:format])
                }.merge(
                  hashes(params[:size], params[:cut], params[:thumbs])
                ).compact
              )
            end,
            "store": (validator_for('Store').call(store: options[:store]) if options[:store])
          }.compact.to_json
        end

        def check_array_param(arr)
          raise Uploadcare::Exception::ValidationError.new("First argument must be an Array") unless arr.is_a?(Array)
        end

        def hashes(size, cut, thumbs)
          {
            size: hash_params('Size', size),
            cut: hash_params('Cut', cut),
            thumbs: hash_params('Thumbs', thumbs)
          }
        end

        def string_params(class_name, param_name, param_value)
          validator_for(class_name)&.call(param_name.to_sym => param_value) unless param_value.nil?
        end

        def hash_params(class_name, params)
          return unless params.is_a?(Hash)

          validator_for(class_name)&.call(**params.transform_keys { |k| k.to_s.downcase.to_sym })
        end

        def validator_for(class_name)
          Object.const_get("Uploadcare::Param::Conversion::Video::Validators::#{class_name}")
        rescue NameError
          nil
        end
      end
    end
  end
end

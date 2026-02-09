# frozen_string_literal: true

module Uploadcare
  class VideoConverter < BaseResource
    attr_accessor :problems, :status, :error, :result

    def initialize(attributes = {}, config = Uploadcare.configuration)
      super
      @video_converter_client = Uploadcare::VideoConverterClient.new(config: config)
      assign_attributes(attributes)
    end

    # Converts a video to a specified format
    # @param video_params [Hash] Contains UUIDs and target format, quality
    # @param options [Hash] Optional parameters such as `store`
    # @return [Array<Hash>] The response containing conversion results for each video
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Video/operation/convertVideo

    def self.convert(params:, options: {}, config: Uploadcare.configuration, request_options: {})
      raise ArgumentError, 'params must include :uuid' unless params[:uuid]
      raise ArgumentError, 'params must include :format' unless params[:format]
      raise ArgumentError, 'params must include :quality' unless params[:quality]

      paths = Array(params[:uuid]).map do |uuid|
        "#{uuid}/video/-/format/#{params[:format]}/-/quality/#{params[:quality]}/"
      end

      video_converter_client = Uploadcare::VideoConverterClient.new(config: config)
      response = Uploadcare::Result.unwrap(video_converter_client.convert_video(paths: paths, options: options,
                                                                                request_options: request_options))
      new(response, config)
    end

    # Fetches the status of a video conversion job by token
    # @param token [String] The job token
    # @return [Hash] The response containing the job status
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Conversion/operation/videoConvertStatus
    def fetch_status(token:, request_options: {})
      response = Uploadcare::Result.unwrap(@video_converter_client.status(token: token,
                                                                          request_options: request_options))
      assign_attributes(response)
      self
    end
  end
end

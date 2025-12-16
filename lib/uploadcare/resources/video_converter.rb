# frozen_string_literal: true

module Uploadcare
  class VideoConverter < BaseResource
    attr_accessor :problems, :status, :error, :result

    def initialize(attributes = {}, config = Uploadcare.configuration)
      super
      @video_converter_client = Uploadcare::VideoConverterClient.new(config)
      assign_attributes(attributes)
    end

    # Converts a video to a specified format
    # @param video_params [Hash] Contains UUIDs and target format, quality
    # @param options [Hash] Optional parameters such as `store`
    # @return [Array<Hash>] The response containing conversion results for each video
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Video/operation/convertVideo

    def self.convert(video_params, options = {}, config = Uploadcare.configuration)
      paths = Array(video_params[:uuid]).map do |uuid|
        "#{uuid}/video/-/format/#{video_params[:format]}/-/quality/#{video_params[:quality]}/"
      end

      video_converter_client = Uploadcare::VideoConverterClient.new(config)
      video_converter_client.convert_video(paths, options)
    end

    # Fetches the status of a video conversion job by token
    # @param token [Integer] The job token
    # @return [Hash] The response containing the job status
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Conversion/operation/videoConvertStatus
    def fetch_status(token)
      response = @video_converter_client.status(token)
      assign_attributes(response)
      self
    end
  end
end

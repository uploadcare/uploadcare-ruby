# frozen_string_literal: true

module Uploadcare
  class DocumentConverter < BaseResource
    attr_accessor :error, :format, :converted_groups, :status, :result

    def initialize(attributes = {}, config = Uploadcare.configuration)
      super
      assign_attributes(attributes)
      @document_client = Uploadcare::DocumentConverterClient.new(config)
    end

    # Fetches information about a document’s format and possible conversion formats
    # @param uuid [String] The UUID of the document
    # @return [Uploadcare::Document] An instance of Document with API response data
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Conversion/operation/documentConvertInfo
    def info(uuid)
      response = @document_client.info(uuid)
      assign_attributes(response)
      self
    end

    # Converts a document to a specified format
    # @param document_params [Hash] Contains UUIDs and target format
    # @param options [Hash] Optional parameters such as `store` and `save_in_group`
    # @return [Array<Hash>] The response containing conversion results for each document
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Conversion/operation/documentConvert

    def self.convert_document(document_params, options = {}, config = Uploadcare.configuration)
      document_client = Uploadcare::DocumentConverterClient.new(config)
      paths = Array(document_params[:uuid]).map do |uuid|
        "#{uuid}/document/-/format/#{document_params[:format]}/"
      end

      document_client.convert_document(paths, options)
    end

    # Fetches document conversion job status by its token
    # @param token [Integer] The job token
    # @return [Uploadcare::DocumentConverter] An instance of DocumentConverter with status data
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Conversion/operation/documentConvertStatus

    def fetch_status(token)
      response = @document_client.status(token)
      assign_attributes(response)
      self
    end
  end
end

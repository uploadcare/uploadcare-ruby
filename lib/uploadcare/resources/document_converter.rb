# frozen_string_literal: true

# Document conversion resource.
class Uploadcare::DocumentConverter < Uploadcare::BaseResource
  attr_accessor :error, :format, :converted_groups, :status, :result

  def initialize(attributes = {}, config = Uploadcare.configuration)
    super
    assign_attributes(attributes)
    @document_client = Uploadcare::DocumentConverterClient.new(config: config)
  end

  # Fetches information about a document’s format and possible conversion formats
  # @param uuid [String] The UUID of the document
  # @return [Uploadcare::Document] An instance of Document with API response data
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Conversion/operation/documentConvertInfo
  def info(uuid:, request_options: {})
    response = Uploadcare::Result.unwrap(@document_client.info(uuid: uuid, request_options: request_options))
    assign_attributes(response)
    self
  end

  # Converts a document to a specified format
  # @param params [Hash] Contains UUIDs and target format
  # @param options [Hash] Optional parameters such as `store` and `save_in_group`
  # @return [Array<Hash>] The response containing conversion results for each document
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Conversion/operation/documentConvert

  def self.convert_document(params:, options: {}, config: Uploadcare.configuration, request_options: {})
    document_client = Uploadcare::DocumentConverterClient.new(config: config)
    paths = Array(params[:uuid]).map do |uuid|
      "#{uuid}/document/-/format/#{params[:format]}/"
    end

    Uploadcare::Result.unwrap(document_client.convert_document(paths: paths, options: options,
                                                               request_options: request_options))
  end

  # Fetches document conversion job status by its token
  # @param token [String] The job token
  # @return [Uploadcare::DocumentConverter] An instance of DocumentConverter with status data
  # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Conversion/operation/documentConvertStatus

  def fetch_status(token:, request_options: {})
    response = Uploadcare::Result.unwrap(@document_client.status(token: token, request_options: request_options))
    assign_attributes(response)
    self
  end
end

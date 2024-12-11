# frozen_string_literal: true

module Uploadcare
  class DocumentConverterClient < RestClient
    # Fetches information about a document's format and possible conversion formats
    # @param uuid [String] The UUID of the document
    # @return [Hash] The response containing document information
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Conversion/operation/documentConvertInfo
    def info(uuid)
      get("/convert/document/#{uuid}/")
    end

    # Converts a document to a specified format.
    # @param paths [Array<String>] Array of document UUIDs and target format
    # @param options [Hash] Optional parameters like `store` and `save_in_group`
    # @return [Hash] The response containing conversion details
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Conversion/operation/documentConvert
    def convert_document(paths, options = {})
      body = {
        paths: paths,
        store: options[:store] ? '1' : '0',
        save_in_group: options[:save_in_group] ? '1' : '0'
      }

      post('/convert/document/', body)
    end

    # Fetches the status of a document conversion job by token
    # @param token [Integer] The job token
    # @return [Hash] The response containing the job status
    # @see https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Conversion/operation/documentConvertStatus
    def status(token)
      get("/convert/document/status/#{token}/")
    end
  end
end

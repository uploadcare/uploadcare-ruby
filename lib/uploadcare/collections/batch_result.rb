# frozen_string_literal: true

# Result object for batch file operations (store/delete).
#
# Wraps the response from batch operations and provides access to:
# - Successfully processed files
# - Files that encountered problems
# - Overall operation status
#
# @example
#   result = client.files.batch_store(uuids: ["uuid1", "uuid2"])
#   result.result.each { |file| puts file.uuid }
#   result.problems.each { |uuid, error| puts "#{uuid}: #{error}" }
class Uploadcare::Collections::BatchResult
  # @return [Integer, nil] HTTP status code of the operation
  attr_reader :status

  # @return [Array<Uploadcare::Resources::File>] Successfully processed File objects
  attr_reader :result

  # @return [Hash] Hash mapping UUIDs to error messages
  attr_reader :problems

  # Initialize a new BatchResult.
  #
  # @param status [Integer, nil] HTTP status code
  # @param result [Array<Hash>] Array of file data hashes from the API
  # @param problems [Hash] Hash of UUIDs to error messages
  # @param client [Uploadcare::Client] Client for creating File objects
  def initialize(status:, result:, problems:, client:)
    @status = status
    @result = result ? result.map { |file_data| Uploadcare::Resources::File.new(file_data, client) } : []
    @problems = problems || {}
  end
end

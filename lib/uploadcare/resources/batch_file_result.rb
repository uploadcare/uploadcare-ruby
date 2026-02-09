# frozen_string_literal: true

# Result object for batch file operations (store/delete)
#
# Wraps the response from batch operations and provides access to:
# - Successfully processed files
# - Files that encountered problems
# - Overall operation status
#
# @example Using batch result
#   result = Uploadcare::File.batch_store(uuids)
#   puts "Status: #{result.status}"
#   puts "Processed: #{result.result.count} files"
#   puts "Problems: #{result.problems.keys.join(', ')}" if result.problems.any?
#
# @see Uploadcare::File.batch_store
# @see Uploadcare::File.batch_delete
class Uploadcare::BatchFileResult
  # @return [Integer] HTTP status code of the operation
  attr_reader :status

  # @return [Array<Uploadcare::File>] Array of successfully processed File objects
  attr_reader :result

  # @return [Hash] Hash of UUIDs that failed with their error messages
  attr_reader :problems

  # Initialize a new BatchFileResult
  #
  # @param status [Integer] HTTP status code
  # @param result [Array<Hash>] Array of file data hashes from the API
  # @param problems [Hash] Hash of UUIDs to error messages
  # @param config [Uploadcare::Configuration] Configuration for creating File objects
  # @return [Uploadcare::BatchFileResult] new batch result instance
  def initialize(status:, result:, problems:, config:)
    @status = status
    @result = result ? result.map { |file_data| Uploadcare::File.new(file_data, config) } : []
    @problems = problems
  end
end

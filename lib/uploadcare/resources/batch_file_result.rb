# frozen_string_literal: true

module Uploadcare
  class BatchFileResult
    attr_reader :status, :result, :problems

    def initialize(status:, result:, problems:, config:)
      @status = status
      @result = result.map { |file_data| File.new(file_data, config) }
      @problems = problems
    end
  end
end

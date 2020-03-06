# frozen_string_literal = true

require 'ostruct'

module Uploadcare
  def self.configuration
    @configuration ||= OpenStruct.new
  end

  def self.configure
    yield(configuration)
  end
end

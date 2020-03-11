# frozen_string_literal = true

require 'ostruct'

module Uploadcare
  # Storage for configuration variables, such as access keys
  def self.configuration
    @configuration ||= OpenStruct.new
  end

  # set configuration
  # @see lib/uploadcare/default_configuration.rb

  def self.configure
    yield(configuration)
  end
end

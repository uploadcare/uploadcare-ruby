# frozen_string_literal: true

Gem.find_files('client/**/*.rb').each { |path| require path }

module Uploadcare
  # Entities represent objects existing in Uploadcare cloud
  #
  # Typically, Entities inherit class methods from {Client} instance methods
  # @see Client
  module Entity
    # @abstract
    class Entity < ApiStruct::Entity
      include Client
    end
  end

  include Entity
end

# frozen_string_literal: true

module Uploadcare
  # @abstract
  # This module is responsible for everything related to generation of request params -
  # such as authentication headers, signatures and serialized uploads
  module Param
  end
  include Param
end

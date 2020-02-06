# frozen_string_literal: true

require 'spec_helper'
require 'uploadcare/concerns/unthrottleable'

module Uploadcare
  RSpec.describe Unthrottleable do
    include Unthrottleable
    def sleep(_time) ; end

    class Throttler
      def initialize
        @called = 0
      end

      def call
        @called += 1
        raise ThrottleError unless @called >= 3
        "Throttler has been called #{@called} times"
      end
    end

    describe 'unthrottleable' do
      it 'attempts to call block multiple times' do
        throttler = Throttler.new
        result = unthrottleable { throttler.call }
        expect(result).to eq 'Throttler has been called 3 times'
      end
    end
  end
end

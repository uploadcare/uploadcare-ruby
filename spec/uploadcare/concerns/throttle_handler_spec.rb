# frozen_string_literal: true

require 'spec_helper'
require 'uploadcare/concern/throttle_handler'

module Uploadcare
  RSpec.describe Concerns::ThrottleHandler do
    include Concerns::ThrottleHandler

    def sleep(_time); end

    before { @called = 0 }

    let(:throttler) do
      lambda do
        @called += 1
        raise ThrottleError if @called < 3

        "Throttler has been called #{@called} times"
      end
    end

    describe 'throttling handling' do
      it 'attempts to call block multiple times' do
        result = handle_throttling { throttler.call }

        expect(result).to eq 'Throttler has been called 3 times'
      end
    end
  end
end

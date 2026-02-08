# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  RSpec.describe ThrottleHandler do
    include ThrottleHandler

    def sleep(_time); end

    before { @called = 0 }

    let(:throttler) do
      lambda do
        @called += 1
        raise Uploadcare::Exception::ThrottleError if @called < 3

        "Throttler has been called #{@called} times"
      end
    end

    describe 'throttling handling' do
      it 'attempts to call block multiple times' do
        result = handle_throttling { throttler.call }

        expect(result).to eq 'Throttler has been called 3 times'
      end

      context 'when max attempts exceeded' do
        let(:always_throttle) do
          lambda do
            raise Uploadcare::Exception::ThrottleError, 0.01
          end
        end

        before do
          allow(Uploadcare.configuration).to receive(:max_throttle_attempts).and_return(2)
        end

        it 'raises ThrottleError after max attempts' do
          expect do
            handle_throttling { always_throttle.call }
          end.to raise_error(Uploadcare::Exception::ThrottleError)
        end
      end
    end
  end
end

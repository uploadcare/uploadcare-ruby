# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Internal::ThrottleHandler do
  let(:handler_class) do
    Class.new do
      include Uploadcare::Internal::ThrottleHandler
    end
  end
  let(:handler) { handler_class.new }

  describe '#handle_throttling' do
    it 'returns the block result when no throttle error occurs' do
      result = handler.handle_throttling(max_attempts: 3) { 'success' }
      expect(result).to eq('success')
    end

    it 'retries on ThrottleError and returns result on success' do
      call_count = 0
      allow(handler).to receive(:sleep)

      result = handler.handle_throttling(max_attempts: 3) do
        call_count += 1
        raise Uploadcare::Exception::ThrottleError.new(timeout: 0.01) if call_count < 2

        'recovered'
      end

      expect(result).to eq('recovered')
      expect(call_count).to eq(2)
    end

    it 'raises ThrottleError when max attempts are exhausted' do
      allow(handler).to receive(:sleep)

      expect do
        handler.handle_throttling(max_attempts: 3) do
          raise Uploadcare::Exception::ThrottleError.new(timeout: 0.01)
        end
      end.to raise_error(Uploadcare::Exception::ThrottleError)
    end

    it 'calls sleep with exponential backoff based on timeout' do
      call_count = 0
      allow(handler).to receive(:sleep)

      begin
        handler.handle_throttling(max_attempts: 4) do
          call_count += 1
          raise Uploadcare::Exception::ThrottleError.new(timeout: 2.0)
        end
      rescue Uploadcare::Exception::ThrottleError
        # expected
      end

      expect(handler).to have_received(:sleep).with(2.0).ordered   # 2.0 * 2^0
      expect(handler).to have_received(:sleep).with(4.0).ordered   # 2.0 * 2^1
      expect(handler).to have_received(:sleep).with(8.0).ordered   # 2.0 * 2^2
    end

    it 'retries exactly max_attempts - 1 times before final attempt' do
      call_count = 0
      allow(handler).to receive(:sleep)

      begin
        handler.handle_throttling(max_attempts: 5) do
          call_count += 1
          raise Uploadcare::Exception::ThrottleError.new(timeout: 0.01)
        end
      rescue Uploadcare::Exception::ThrottleError
        # expected
      end

      expect(call_count).to eq(5)
      expect(handler).to have_received(:sleep).exactly(4).times
    end

    it 'does not retry when max_attempts is 1' do
      call_count = 0
      allow(handler).to receive(:sleep)

      expect do
        handler.handle_throttling(max_attempts: 1) do
          call_count += 1
          raise Uploadcare::Exception::ThrottleError.new(timeout: 0.01)
        end
      end.to raise_error(Uploadcare::Exception::ThrottleError)

      expect(call_count).to eq(1)
      expect(handler).not_to have_received(:sleep)
    end

    it 'raises ArgumentError when max_attempts is not positive' do
      expect do
        handler.handle_throttling(max_attempts: 0) { 'nope' }
      end.to raise_error(ArgumentError, 'max_attempts must be at least 1')
    end

    it 'does not catch non-ThrottleError exceptions' do
      expect do
        handler.handle_throttling(max_attempts: 3) do
          raise StandardError, 'something else'
        end
      end.to raise_error(StandardError, 'something else')
    end

    context 'when max_attempts is nil and handler responds to config' do
      it 'uses config.max_throttle_attempts' do
        config = Uploadcare::Configuration.new(
          public_key: 'test',
          secret_key: 'test',
          max_throttle_attempts: 2
        )
        handler_with_config = handler_class.new
        allow(handler_with_config).to receive(:config).and_return(config)
        allow(handler_with_config).to receive(:sleep)

        call_count = 0
        begin
          handler_with_config.handle_throttling do
            call_count += 1
            raise Uploadcare::Exception::ThrottleError.new(timeout: 0.01)
          end
        rescue Uploadcare::Exception::ThrottleError
          # expected
        end

        expect(call_count).to eq(2)
      end
    end
  end
end

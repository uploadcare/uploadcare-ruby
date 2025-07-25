# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::ThrottleHandler do
  let(:test_class) do
    Class.new do
      include Uploadcare::ThrottleHandler
    end
  end

  let(:handler) { test_class.new }

  before do
    allow(Uploadcare).to receive(:configuration).and_return(
      double('configuration', max_throttle_attempts: 5)
    )
  end

  describe '#handle_throttling' do
    context 'when block executes successfully' do
      it 'returns the block result' do
        result = handler.handle_throttling { 'success' }
        expect(result).to eq('success')
      end

      it 'executes block only once' do
        call_count = 0
        handler.handle_throttling { call_count += 1 }
        expect(call_count).to eq(1)
      end
    end

    context 'when block raises ThrottleError' do
      let(:throttle_error) do
        error = Uploadcare::Exception::ThrottleError.new('Rate limited')
        allow(error).to receive(:timeout).and_return(0.01) # Short timeout for tests
        error
      end

      context 'and succeeds on retry' do
        it 'retries and returns successful result' do
          attempts = 0
          result = handler.handle_throttling do
            attempts += 1
            raise throttle_error if attempts < 3
            'success after retries'
          end

          expect(result).to eq('success after retries')
          expect(attempts).to eq(3)
        end

        it 'sleeps for the specified timeout' do
          attempts = 0
          expect(handler).to receive(:sleep).with(0.01).twice

          handler.handle_throttling do
            attempts += 1
            raise throttle_error if attempts < 3
            'success'
          end
        end
      end

      context 'and fails all attempts' do
        it 'raises ThrottleError after max attempts' do
          attempts = 0
          
          expect do
            handler.handle_throttling do
              attempts += 1
              raise throttle_error
            end
          end.to raise_error(Uploadcare::Exception::ThrottleError, 'Rate limited')

          expect(attempts).to eq(5) # max_throttle_attempts
        end

        it 'sleeps between each retry' do
          expect(handler).to receive(:sleep).with(0.01).exactly(4).times

          expect do
            handler.handle_throttling { raise throttle_error }
          end.to raise_error(Uploadcare::Exception::ThrottleError)
        end
      end

      context 'with different max_throttle_attempts' do
        before do
          allow(Uploadcare).to receive(:configuration).and_return(
            double('configuration', max_throttle_attempts: 3)
          )
        end

        it 'respects configured max attempts' do
          attempts = 0
          
          expect do
            handler.handle_throttling do
              attempts += 1
              raise throttle_error
            end
          end.to raise_error(Uploadcare::Exception::ThrottleError)

          expect(attempts).to eq(3)
        end

        it 'sleeps correct number of times' do
          expect(handler).to receive(:sleep).with(0.01).exactly(2).times

          expect do
            handler.handle_throttling { raise throttle_error }
          end.to raise_error(Uploadcare::Exception::ThrottleError)
        end
      end

      context 'with max_throttle_attempts set to 1' do
        before do
          allow(Uploadcare).to receive(:configuration).and_return(
            double('configuration', max_throttle_attempts: 1)
          )
        end

        it 'does not retry' do
          attempts = 0
          
          expect do
            handler.handle_throttling do
              attempts += 1
              raise throttle_error
            end
          end.to raise_error(Uploadcare::Exception::ThrottleError)

          expect(attempts).to eq(1)
        end

        it 'does not sleep' do
          expect(handler).not_to receive(:sleep)

          expect do
            handler.handle_throttling { raise throttle_error }
          end.to raise_error(Uploadcare::Exception::ThrottleError)
        end
      end
    end

    context 'when block raises other errors' do
      it 'does not retry on non-ThrottleError' do
        attempts = 0
        
        expect do
          handler.handle_throttling do
            attempts += 1
            raise StandardError, 'Other error'
          end
        end.to raise_error(StandardError, 'Other error')

        expect(attempts).to eq(1)
      end

      it 'does not catch the error' do
        expect do
          handler.handle_throttling { raise ArgumentError, 'Bad argument' }
        end.to raise_error(ArgumentError, 'Bad argument')
      end
    end

    context 'with varying timeout values' do
      it 'uses timeout from each error instance' do
        attempts = 0
        timeouts = [0.01, 0.02, 0.03]
        
        timeouts.each_with_index do |timeout, index|
          error = Uploadcare::Exception::ThrottleError.new("Attempt #{index + 1}")
          allow(error).to receive(:timeout).and_return(timeout)
          
          expect(handler).to receive(:sleep).with(timeout).ordered if index < timeouts.length - 1
        end

        result = handler.handle_throttling do
          attempts += 1
          if attempts <= timeouts.length
            error = Uploadcare::Exception::ThrottleError.new("Attempt #{attempts}")
            allow(error).to receive(:timeout).and_return(timeouts[attempts - 1])
            raise error
          end
          'success'
        end

        expect(result).to eq('success')
      end
    end

    context 'with block that modifies state' do
      it 'preserves state changes across retries' do
        counter = 0
        
        result = handler.handle_throttling do
          counter += 1
          raise throttle_error if counter < 3
          counter
        end

        expect(result).to eq(3)
        expect(counter).to eq(3)
      end
    end
  end
end
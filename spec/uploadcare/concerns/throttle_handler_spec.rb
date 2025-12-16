# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  RSpec.describe ThrottleHandler do
    let(:dummy_class) do
      Class.new do
        include Uploadcare::ThrottleHandler

        def sleep(_time); end
      end
    end
    let(:instance) { dummy_class.new }

    before do
      allow(Uploadcare).to receive(:configuration).and_return(
        double('configuration', max_throttle_attempts: 5)
      )
    end

    describe '#handle_throttling' do
      context 'when block succeeds on first attempt' do
        it 'returns the result immediately' do
          result = instance.handle_throttling { 'success' }
          expect(result).to eq('success')
        end

        it 'does not sleep' do
          expect(instance).not_to receive(:sleep)
          instance.handle_throttling { 'success' }
        end
      end

      context 'when block is throttled once then succeeds' do
        let(:call_count) { 0 }

        it 'retries and returns success result' do
          call_count = 0
          result = instance.handle_throttling do
            call_count += 1
            raise Uploadcare::Exception::ThrottleError.new(1.0) if call_count == 1

            "success on attempt #{call_count}"
          end

          expect(result).to eq('success on attempt 2')
        end

        it 'sleeps for the specified timeout' do
          call_count = 0
          expect(instance).to receive(:sleep).with(2.5).once

          instance.handle_throttling do
            call_count += 1
            raise Uploadcare::Exception::ThrottleError.new(2.5) if call_count == 1

            'success'
          end
        end
      end

      context 'when block is throttled multiple times then succeeds' do
        it 'retries the correct number of times' do
          call_count = 0
          result = instance.handle_throttling do
            call_count += 1
            raise Uploadcare::Exception::ThrottleError.new(0.1) if call_count < 3

            "success on attempt #{call_count}"
          end

          expect(result).to eq('success on attempt 3')
        end

        it 'sleeps for each throttle timeout' do
          call_count = 0
          expect(instance).to receive(:sleep).with(1.0).once
          expect(instance).to receive(:sleep).with(2.0).once

          instance.handle_throttling do
            call_count += 1
            case call_count
            when 1
              raise Uploadcare::Exception::ThrottleError.new(1.0)
            when 2
              raise Uploadcare::Exception::ThrottleError.new(2.0)
            else
              'success'
            end
          end
        end
      end

      context 'when max attempts is reached' do
        before do
          allow(Uploadcare.configuration).to receive(:max_throttle_attempts).and_return(3)
        end

        it 'raises the final ThrottleError after exhausting retries' do
          call_count = 0
          expect do
            instance.handle_throttling do
              call_count += 1
              raise Uploadcare::Exception::ThrottleError.new(1.0)
            end
          end.to raise_error(Uploadcare::Exception::ThrottleError) do |error|
            expect(error.timeout).to eq(1.0)
          end

          expect(call_count).to eq(3)
        end

        it 'sleeps before each retry but not on the final attempt' do
          call_count = 0
          expect(instance).to receive(:sleep).with(1.0).exactly(2).times

          expect do
            instance.handle_throttling do
              call_count += 1
              raise Uploadcare::Exception::ThrottleError.new(1.0)
            end
          end.to raise_error(Uploadcare::Exception::ThrottleError)
        end
      end

      context 'when non-ThrottleError is raised' do
        it 'does not catch other exceptions' do
          expect do
            instance.handle_throttling do
              raise StandardError, 'other error'
            end
          end.to raise_error(StandardError, 'other error')
        end

        it 'does not retry for other exceptions' do
          call_count = 0
          expect do
            instance.handle_throttling do
              call_count += 1
              raise ArgumentError, 'invalid argument'
            end
          end.to raise_error(ArgumentError, 'invalid argument')

          expect(call_count).to eq(1)
        end
      end

      context 'with different timeout values' do
        it 'respects zero timeout' do
          call_count = 0
          expect(instance).to receive(:sleep).with(0).once

          instance.handle_throttling do
            call_count += 1
            raise Uploadcare::Exception::ThrottleError.new(0) if call_count == 1

            'success'
          end
        end

        it 'respects fractional timeout values' do
          call_count = 0
          expect(instance).to receive(:sleep).with(0.5).once

          instance.handle_throttling do
            call_count += 1
            raise Uploadcare::Exception::ThrottleError.new(0.5) if call_count == 1

            'success'
          end
        end

        it 'respects large timeout values' do
          call_count = 0
          expect(instance).to receive(:sleep).with(300.0).once

          instance.handle_throttling do
            call_count += 1
            raise Uploadcare::Exception::ThrottleError.new(300.0) if call_count == 1

            'success'
          end
        end
      end

      context 'with different max_throttle_attempts configurations' do
        it 'respects max_throttle_attempts = 1 (no retries)' do
          allow(Uploadcare.configuration).to receive(:max_throttle_attempts).and_return(1)

          call_count = 0
          expect do
            instance.handle_throttling do
              call_count += 1
              raise Uploadcare::Exception::ThrottleError.new(1.0)
            end
          end.to raise_error(Uploadcare::Exception::ThrottleError)

          expect(call_count).to eq(1)
        end

        it 'respects max_throttle_attempts = 10' do
          allow(Uploadcare.configuration).to receive(:max_throttle_attempts).and_return(10)

          call_count = 0
          result = instance.handle_throttling do
            call_count += 1
            raise Uploadcare::Exception::ThrottleError.new(0.01) if call_count < 7

            "success on attempt #{call_count}"
          end

          expect(result).to eq('success on attempt 7')
        end
      end

      context 'with block return values' do
        it 'preserves nil return values' do
          result = instance.handle_throttling { nil }
          expect(result).to be_nil
        end

        it 'preserves false return values' do
          result = instance.handle_throttling { false }
          expect(result).to eq(false)
        end

        it 'preserves empty string return values' do
          result = instance.handle_throttling { '' }
          expect(result).to eq('')
        end

        it 'preserves hash return values' do
          expected = { key: 'value', number: 42 }
          result = instance.handle_throttling { expected }
          expect(result).to eq(expected)
        end

        it 'preserves array return values' do
          expected = [1, 2, 'three', { four: 4 }]
          result = instance.handle_throttling { expected }
          expect(result).to eq(expected)
        end
      end

      context 'real-world scenarios' do
        it 'handles API rate limiting scenario' do
          api_calls = 0
          expect(instance).to receive(:sleep).with(60.0).once

          result = instance.handle_throttling do
            api_calls += 1
            raise Uploadcare::Exception::ThrottleError.new(60.0) if api_calls == 1

            { status: 'success', data: 'api_response' }
          end

          expect(result).to eq({ status: 'success', data: 'api_response' })
        end

        it 'handles upload throttling scenario' do
          upload_attempts = 0
          timeouts = [5.0, 10.0]
          timeout_index = 0

          expect(instance).to receive(:sleep).with(5.0).once
          expect(instance).to receive(:sleep).with(10.0).once

          result = instance.handle_throttling do
            upload_attempts += 1
            if upload_attempts <= 2
              timeout = timeouts[timeout_index]
              timeout_index += 1
              raise Uploadcare::Exception::ThrottleError.new(timeout)
            end

            'upload_successful'
          end

          expect(result).to eq('upload_successful')
        end

        it 'handles conversion service throttling' do
          conversion_attempts = 0

          result = instance.handle_throttling do
            conversion_attempts += 1
            raise Uploadcare::Exception::ThrottleError.new(30.0) if conversion_attempts < 4

            { job_id: 'conv_123', status: 'processing' }
          end

          expect(result).to eq({ job_id: 'conv_123', status: 'processing' })
          expect(conversion_attempts).to eq(4)
        end
      end

      context 'edge cases' do
        it 'handles ThrottleError without timeout (default)' do
          call_count = 0
          expect(instance).to receive(:sleep).with(10.0).once

          instance.handle_throttling do
            call_count += 1
            raise Uploadcare::Exception::ThrottleError if call_count == 1

            'success'
          end
        end

        it 'handles block that yields values' do
          result = instance.handle_throttling do |*args|
            expect(args).to be_empty
            'block_result'
          end

          expect(result).to eq('block_result')
        end
      end
    end

    describe 'module integration' do
      it 'can be included in classes' do
        expect(dummy_class.ancestors).to include(Uploadcare::ThrottleHandler)
        expect(instance).to respond_to(:handle_throttling)
      end

      it 'makes handle_throttling method available' do
        expect(instance.public_methods).to include(:handle_throttling)
      end
    end
  end
end

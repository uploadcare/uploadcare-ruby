# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Exception::ThrottleError do
  describe '#initialize' do
    it 'inherits from StandardError' do
      expect(described_class.superclass).to eq(StandardError)
    end

    it 'can be instantiated with default timeout' do
      error = described_class.new
      expect(error.timeout).to eq(10.0)
      expect(error.message).to eq('Uploadcare::Exception::ThrottleError')
    end

    it 'can be instantiated with custom timeout' do
      error = described_class.new(30.0)
      expect(error.timeout).to eq(30.0)
    end

    it 'stores timeout as an accessible attribute' do
      error = described_class.new(15.5)
      expect(error.timeout).to eq(15.5)
    end
  end

  describe '#timeout' do
    it 'returns the timeout value' do
      error = described_class.new(25.0)
      expect(error.timeout).to eq(25.0)
    end

    it 'is read-only' do
      error = described_class.new(20.0)
      expect { error.timeout = 30.0 }.to raise_error(NoMethodError)
    end
  end

  describe 'raising the error' do
    it 'can be raised as an exception' do
      expect { raise described_class }.to raise_error(described_class)
    end

    it 'can be raised with a timeout' do
      expect { raise described_class, 60.0 }
        .to raise_error(described_class) do |error|
          expect(error.timeout).to eq(60.0)
        end
    end
  end

  describe 'rescue behavior' do
    it 'can be rescued as ThrottleError' do
      result = begin
        raise described_class, 45.0
      rescue described_class => e
        e.timeout
      end
      expect(result).to eq(45.0)
    end

    it 'can be rescued as StandardError' do
      result = begin
        raise described_class, 15.0
      rescue StandardError => e
        e.is_a?(described_class)
      end
      expect(result).to be true
    end
  end

  describe 'use cases' do
    context 'when API rate limit is exceeded' do
      it 'provides timeout information for retry logic' do
        error = described_class.new(30.0)
        expect(error.timeout).to eq(30.0)
      end

      it 'can use different timeouts for different scenarios' do
        short_throttle = described_class.new(5.0)
        long_throttle = described_class.new(120.0)

        expect(short_throttle.timeout).to eq(5.0)
        expect(long_throttle.timeout).to eq(120.0)
      end
    end

    context 'in throttle handling logic' do
      it 'can be used to implement backoff' do
        raise described_class, 2.0
      rescue described_class => e
        sleep_time = e.timeout
        expect(sleep_time).to eq(2.0)
      end

      it 'preserves timeout through exception chain' do
        original_timeout = 25.5

        begin
          begin
            raise described_class, original_timeout
          rescue described_class => e
            raise e # re-raise
          end
        rescue described_class => e
          expect(e.timeout).to eq(original_timeout)
        end
      end
    end

    context 'with retry-after headers' do
      it 'can represent server-specified retry delays' do
        # Simulating a 429 response with Retry-After header
        retry_after_seconds = 45.0
        error = described_class.new(retry_after_seconds)

        expect(error.timeout).to eq(retry_after_seconds)
      end
    end
  end

  describe 'edge cases' do
    it 'handles zero timeout' do
      error = described_class.new(0.0)
      expect(error.timeout).to eq(0.0)
    end

    it 'handles fractional timeouts' do
      error = described_class.new(0.5)
      expect(error.timeout).to eq(0.5)
    end

    it 'handles very large timeouts' do
      error = described_class.new(3600.0)
      expect(error.timeout).to eq(3600.0)
    end
  end
end

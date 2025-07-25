# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Exception::RetryError do
  describe '#initialize' do
    it 'inherits from StandardError' do
      expect(described_class.superclass).to eq(StandardError)
    end

    it 'can be instantiated with a message' do
      error = described_class.new('Request needs retry')
      expect(error.message).to eq('Request needs retry')
    end

    it 'can be instantiated without a message' do
      error = described_class.new
      expect(error.message).to eq('Uploadcare::Exception::RetryError')
    end
  end

  describe 'raising the error' do
    it 'can be raised as an exception' do
      expect { raise described_class }.to raise_error(described_class)
    end

    it 'can be raised with a custom message' do
      expect { raise described_class, 'Network timeout, retry needed' }
        .to raise_error(described_class, 'Network timeout, retry needed')
    end
  end

  describe 'rescue behavior' do
    it 'can be rescued as RetryError' do
      result = begin
        raise described_class, 'Retry required'
      rescue described_class => e
        e.message
      end
      expect(result).to eq('Retry required')
    end

    it 'can be rescued as StandardError' do
      result = begin
        raise described_class, 'Retry required'
      rescue StandardError => e
        e.message
      end
      expect(result).to eq('Retry required')
    end
  end

  describe 'use cases' do
    context 'when network issues occur' do
      it 'can indicate connection problems' do
        error = described_class.new('Connection reset by peer')
        expect(error.message).to eq('Connection reset by peer')
      end

      it 'can indicate timeout issues' do
        error = described_class.new('Request timeout after 30 seconds')
        expect(error.message).to eq('Request timeout after 30 seconds')
      end
    end

    context 'when server returns retryable errors' do
      it 'can indicate 503 Service Unavailable' do
        error = described_class.new('503: Service temporarily unavailable')
        expect(error.message).to eq('503: Service temporarily unavailable')
      end

      it 'can indicate 502 Bad Gateway' do
        error = described_class.new('502: Bad Gateway')
        expect(error.message).to eq('502: Bad Gateway')
      end
    end

    context 'in retry middleware' do
      it 'can be used to trigger retry logic' do
        retries = 0
        max_retries = 3

        begin
          retries += 1
          raise described_class, 'Temporary failure' if retries < max_retries

          'Success'
        rescue described_class
          retry if retries < max_retries
        end

        expect(retries).to eq(max_retries)
      end
    end
  end
end

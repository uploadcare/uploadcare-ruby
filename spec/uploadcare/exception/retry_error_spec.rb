# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Exception::RetryError do
  describe 'inheritance' do
    it 'inherits from StandardError' do
      expect(described_class).to be < StandardError
    end
  end

  describe 'initialization' do
    it 'can be initialized without arguments' do
      expect { described_class.new }.not_to raise_error
    end

    it 'can be initialized with a message' do
      error = described_class.new('Retry required')
      expect(error.message).to eq('Retry required')
    end

    it 'accepts retry-specific messages' do
      message = 'Request failed, retry in 5 seconds'
      error = described_class.new(message)
      expect(error.message).to eq(message)
    end
  end

  describe 'raising and catching' do
    it 'can be raised and caught' do
      expect do
        raise described_class, 'Retry error'
      end.to raise_error(described_class, 'Retry error')
    end

    it 'can be caught as StandardError' do
      expect do
        raise described_class, 'Retry error'
      end.to raise_error(StandardError)
    end

    it 'can be caught as Uploadcare::Exception::RetryError' do
      expect do
        raise described_class, 'Retry error'
      end.to raise_error(Uploadcare::Exception::RetryError)
    end
  end

  describe 'retry scenarios' do
    it 'handles temporary service unavailable errors' do
      expect do
        raise described_class, 'Service temporarily unavailable, retry after 30 seconds'
      end.to raise_error(described_class, 'Service temporarily unavailable, retry after 30 seconds')
    end

    it 'handles rate limiting scenarios' do
      expect do
        raise described_class, 'Rate limit exceeded, retry after 60 seconds'
      end.to raise_error(described_class, 'Rate limit exceeded, retry after 60 seconds')
    end

    it 'handles server overload scenarios' do
      expect do
        raise described_class, 'Server overloaded, please retry with exponential backoff'
      end.to raise_error(described_class, 'Server overloaded, please retry with exponential backoff')
    end

    it 'handles network connectivity issues' do
      expect do
        raise described_class, 'Network connectivity issue detected, retry recommended'
      end.to raise_error(described_class, 'Network connectivity issue detected, retry recommended')
    end
  end

  describe 'upload retry scenarios' do
    it 'handles partial upload failures' do
      expect do
        raise described_class, 'Upload partially failed, resume from chunk 5 of 10'
      end.to raise_error(described_class, 'Upload partially failed, resume from chunk 5 of 10')
    end

    it 'handles multipart upload interruption' do
      expect do
        raise described_class, 'Multipart upload interrupted, retry remaining parts'
      end.to raise_error(described_class, 'Multipart upload interrupted, retry remaining parts')
    end

    it 'handles upload timeout scenarios' do
      expect do
        raise described_class, 'Upload timed out due to slow connection, retry with smaller chunks'
      end.to raise_error(described_class, 'Upload timed out due to slow connection, retry with smaller chunks')
    end
  end

  describe 'API retry scenarios' do
    it 'handles temporary API errors' do
      expect do
        raise described_class, 'API temporarily unavailable (HTTP 503), retry in 10 seconds'
      end.to raise_error(described_class, 'API temporarily unavailable (HTTP 503), retry in 10 seconds')
    end

    it 'handles processing queue backlog' do
      expect do
        raise described_class, 'Processing queue full, retry request later'
      end.to raise_error(described_class, 'Processing queue full, retry request later')
    end

    it 'handles maintenance mode scenarios' do
      expect do
        raise described_class, 'Service in maintenance mode, retry after maintenance window'
      end.to raise_error(described_class, 'Service in maintenance mode, retry after maintenance window')
    end
  end

  describe 'conversion retry scenarios' do
    it 'handles temporary conversion service errors' do
      expect do
        raise described_class, 'Conversion service busy, retry conversion job'
      end.to raise_error(described_class, 'Conversion service busy, retry conversion job')
    end

    it 'handles conversion queue overflow' do
      expect do
        raise described_class, 'Conversion queue at capacity, retry job submission'
      end.to raise_error(described_class, 'Conversion queue at capacity, retry job submission')
    end

    it 'handles worker node failures' do
      expect do
        raise described_class, 'Conversion worker failed, job will be retried automatically'
      end.to raise_error(described_class, 'Conversion worker failed, job will be retried automatically')
    end
  end

  describe 'retry strategy scenarios' do
    it 'handles exponential backoff recommendations' do
      expect do
        raise described_class, 'Use exponential backoff: retry after 1, 2, 4, 8 seconds'
      end.to raise_error(described_class, 'Use exponential backoff: retry after 1, 2, 4, 8 seconds')
    end

    it 'handles linear backoff recommendations' do
      expect do
        raise described_class, 'Use linear backoff: retry every 5 seconds, max 5 attempts'
      end.to raise_error(described_class, 'Use linear backoff: retry every 5 seconds, max 5 attempts')
    end

    it 'handles jittered retry recommendations' do
      expect do
        raise described_class, 'Add random jitter to prevent thundering herd: base 10s ± 2s'
      end.to raise_error(described_class, 'Add random jitter to prevent thundering herd: base 10s ± 2s')
    end
  end

  describe 'context-aware retry messages' do
    it 'handles request context in retry messages' do
      context_message = "Retry Error for request:\n  " \
                        "Method: POST\n  " \
                        "Endpoint: /files/\n  " \
                        "Attempt: 3/5\n  " \
                        'Next retry: 2024-01-01T12:00:30Z'

      expect do
        raise described_class, context_message
      end.to raise_error(described_class, context_message)
    end

    it 'handles operation-specific retry guidance' do
      expect do
        raise described_class, 'File upload retry: consider reducing chunk size or using direct upload'
      end.to raise_error(described_class, 'File upload retry: consider reducing chunk size or using direct upload')
    end
  end

  describe 'message formatting' do
    it 'preserves detailed retry instructions' do
      detailed_message = "Retry Required:\n  " \
                         "Reason: Temporary server overload\n  " \
                         "Suggested delay: 45 seconds\n  " \
                         "Max retries: 3\n  " \
                         'Backoff strategy: exponential'
      error = described_class.new(detailed_message)
      expect(error.message).to eq(detailed_message)
    end

    it 'handles structured retry data' do
      structured_data = {
        retry_after: 30,
        max_attempts: 5,
        strategy: 'exponential',
        reason: 'rate_limited'
      }.to_s

      error = described_class.new(structured_data)
      expect(error.message).to include('retry_after')
      expect(error.message).to include('exponential')
    end
  end

  describe 'error chaining scenarios' do
    it 'handles original error context' do
      original_error = StandardError.new('Connection timeout')
      retry_message = "Retry required due to: #{original_error.message}"

      expect do
        raise described_class, retry_message
      end.to raise_error(described_class, retry_message)
    end

    it 'preserves error hierarchy for retry decisions' do
      expect do
        raise described_class, 'Retryable error: upstream service returned 503'
      end.to raise_error(described_class, /Retryable error.*503/)
    end
  end

  describe 'backtrace handling' do
    it 'preserves backtrace information' do
      raise described_class, 'Retry needed'
    rescue described_class => e
      expect(e.backtrace).to be_an(Array)
      expect(e.backtrace.first).to include(__FILE__)
    end

    it 'maintains context across retry attempts' do
      attempt = 1
      begin
        attempt += 1
        raise described_class, "Retry attempt #{attempt}"
      rescue described_class => e
        expect(e.message).to include('attempt')
        expect(e.backtrace).to be_an(Array)
        expect(e.backtrace).not_to be_empty
      end
    end
  end
end

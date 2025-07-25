# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Middleware::Retry do
  let(:app) { double('app') }
  let(:logger) { instance_double(Logger) }
  let(:middleware) { described_class.new(app, logger: logger) }
  let(:env) do
    {
      method: :get,
      url: 'https://api.uploadcare.com/test'
    }
  end

  describe '#call' do
    context 'when request succeeds' do
      let(:response) { { status: 200, body: 'success' } }

      it 'returns response without retry' do
        expect(app).to receive(:call).once.and_return(response)
        expect(middleware.call(env)).to eq(response)
      end
    end

    context 'when request fails with retryable status' do
      let(:failed_response) { { status: 503, headers: {} } }
      let(:success_response) { { status: 200, body: 'success' } }

      before do
        allow(middleware).to receive(:sleep) # Don't actually sleep in tests
        allow(logger).to receive(:warn)
      end

      it 'retries and succeeds' do
        expect(app).to receive(:call).and_return(failed_response, success_response)
        expect(middleware.call(env)).to eq(success_response)
      end

      it 'logs retry attempts' do
        allow(app).to receive(:call).and_return(failed_response, success_response)
        expect(logger).to receive(:warn).with(/Retrying GET.*attempt 1\/3.*status code 503/)
        middleware.call(env)
      end

      it 'respects max retries' do
        allow(app).to receive(:call).and_return(failed_response)
        middleware = described_class.new(app, max_retries: 2, logger: logger)
        allow(middleware).to receive(:sleep)
        
        expect(app).to receive(:call).exactly(3).times # initial + 2 retries
        middleware.call(env)
      end
    end

    context 'with retry-after header' do
      let(:failed_response) { { status: 429, headers: { 'retry-after' => '5' } } }
      let(:success_response) { { status: 200 } }

      it 'uses retry-after value for delay' do
        allow(app).to receive(:call).and_return(failed_response, success_response)
        allow(logger).to receive(:warn)
        
        expect(middleware).to receive(:sleep).with(satisfy { |val| val >= 5 })
        middleware.call(env)
      end
    end

    context 'with connection errors' do
      let(:error) { Faraday::TimeoutError.new('timeout') }
      let(:success_response) { { status: 200 } }

      before do
        allow(middleware).to receive(:sleep)
        allow(logger).to receive(:warn)
      end

      it 'retries on timeout errors' do
        expect(app).to receive(:call).and_raise(error).ordered
        expect(app).to receive(:call).and_return(success_response).ordered
        
        expect(middleware.call(env)).to eq(success_response)
      end

      it 'does not retry non-retryable errors' do
        non_retryable_error = StandardError.new('other error')
        expect(app).to receive(:call).once.and_raise(non_retryable_error)
        
        expect { middleware.call(env) }.to raise_error(StandardError, 'other error')
      end
    end

    context 'with non-retryable methods' do
      let(:post_env) { env.merge(method: :post) }
      let(:failed_response) { { status: 503 } }

      it 'does not retry POST requests by default' do
        expect(app).to receive(:call).once.and_return(failed_response)
        expect(middleware.call(post_env)).to eq(failed_response)
      end
    end

    context 'with custom retry logic' do
      let(:custom_retry) { ->(env, response) { response[:status] == 418 } }
      let(:middleware) do
        described_class.new(app, retry_if: custom_retry, logger: logger)
      end
      let(:teapot_response) { { status: 418 } }
      let(:success_response) { { status: 200 } }

      it 'uses custom retry logic' do
        allow(middleware).to receive(:sleep)
        allow(logger).to receive(:warn)
        
        expect(app).to receive(:call).and_return(teapot_response, success_response)
        expect(middleware.call(env)).to eq(success_response)
      end
    end
  end

  describe '#calculate_delay' do
    it 'uses exponential backoff' do
      middleware = described_class.new(app, backoff_factor: 2)
      
      expect(middleware.send(:calculate_delay, 1)).to be_between(1, 1.3)
      expect(middleware.send(:calculate_delay, 2)).to be_between(2, 2.6)
      expect(middleware.send(:calculate_delay, 3)).to be_between(4, 5.2)
    end
  end
end
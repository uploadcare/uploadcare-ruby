# frozen_string_literal: true

require 'spec_helper'
require 'logger'

RSpec.describe Uploadcare::Middleware::Logger do
  let(:app) { double('app') }
  let(:logger) { instance_double(::Logger) }
  let(:middleware) { described_class.new(app, logger) }
  let(:env) do
    {
      method: :get,
      url: 'https://api.uploadcare.com/test',
      request_headers: { 'Authorization' => 'Bearer token' },
      body: { secret_key: 'secret' }
    }
  end

  describe '#call' do
    context 'when request succeeds' do
      let(:response) { { status: 200, headers: {}, body: { result: 'success' } } }

      before do
        allow(app).to receive(:call).and_return(response)
        allow(logger).to receive(:info)
        allow(logger).to receive(:debug)
      end

      it 'logs the request' do
        expect(logger).to receive(:info).with('[Uploadcare] Request: GET https://api.uploadcare.com/test')
        middleware.call(env)
      end

      it 'logs the response' do
        expect(logger).to receive(:info).with(/\[Uploadcare\] Response: 200 \(\d+\.\d+ms\)/)
        middleware.call(env)
      end

      it 'filters sensitive headers' do
        expect(logger).to receive(:debug).with(
          '[Uploadcare] Headers: {"authorization"=>"[FILTERED]"}'
        )
        middleware.call(env)
      end

      it 'filters sensitive body data' do
        expect(logger).to receive(:debug).with(
          '[Uploadcare] Body: {:secret_key=>"[FILTERED]"}'
        )
        middleware.call(env)
      end

      it 'returns the response' do
        expect(middleware.call(env)).to eq(response)
      end
    end

    context 'when request fails' do
      let(:error) { StandardError.new('Connection failed') }

      before do
        allow(app).to receive(:call).and_raise(error)
        allow(logger).to receive(:info)
        allow(logger).to receive(:error)
      end

      it 'logs the error' do
        expect(logger).to receive(:error).with(/\[Uploadcare\] Error: StandardError - Connection failed/)
        expect { middleware.call(env) }.to raise_error(StandardError)
      end

      it 're-raises the error' do
        expect { middleware.call(env) }.to raise_error(StandardError, 'Connection failed')
      end
    end

    context 'with default logger' do
      let(:middleware) { described_class.new(app) }

      it 'uses stdout logger by default' do
        allow(app).to receive(:call).and_return({ status: 200 })
        expect { middleware.call(env) }.to output(/\[Uploadcare\] Request/).to_stdout
      end
    end
  end

  describe '#truncate' do
    it 'truncates long strings' do
      long_string = 'a' * 2000
      result = middleware.send(:truncate, long_string, 100)
      expect(result).to eq('a' * 100 + '... (truncated)')
    end

    it 'does not truncate short strings' do
      short_string = 'short'
      result = middleware.send(:truncate, short_string, 100)
      expect(result).to eq('short')
    end
  end
end
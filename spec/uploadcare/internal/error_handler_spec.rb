# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Internal::ErrorHandler do
  let(:handler) do
    Class.new { include Uploadcare::Internal::ErrorHandler }.new
  end

  def faraday_error(status:, body:, headers: {})
    response = { status: status, body: body, headers: headers }
    Faraday::ClientError.new('request failed', response)
  end

  describe '#handle_error' do
    context 'when response is nil' do
      it 'raises RequestError with the error message' do
        error = Faraday::ClientError.new('connection refused')
        expect { handler.handle_error(error) }.to raise_error(
          Uploadcare::Exception::RequestError, 'connection refused'
        )
      end
    end

    context 'with HTTP 400' do
      it 'raises InvalidRequestError' do
        error = faraday_error(status: 400, body: '{"detail":"Bad request param"}')
        expect { handler.handle_error(error) }.to raise_error(
          Uploadcare::Exception::InvalidRequestError, 'Bad request param'
        )
      end
    end

    context 'with HTTP 404' do
      it 'raises NotFoundError' do
        error = faraday_error(status: 404, body: '{"detail":"Not found."}')
        expect { handler.handle_error(error) }.to raise_error(
          Uploadcare::Exception::NotFoundError, 'Not found.'
        )
      end
    end

    context 'with HTTP 429' do
      it 'raises ThrottleError' do
        error = faraday_error(
          status: 429,
          body: '{"detail":"Request was throttled."}',
          headers: { 'retry-after' => '5' }
        )
        expect { handler.handle_error(error) }.to raise_error(
          Uploadcare::Exception::ThrottleError
        )
      end

      it 'sets timeout from retry-after header' do
        error = faraday_error(
          status: 429,
          body: '{"detail":"Throttled"}',
          headers: { 'retry-after' => '7.5' }
        )
        begin
          handler.handle_error(error)
        rescue Uploadcare::Exception::ThrottleError => e
          expect(e.timeout).to eq(7.5)
        end
      end

      it 'defaults timeout to 10.0 when retry-after is missing' do
        error = faraday_error(status: 429, body: '{"detail":"Throttled"}')
        begin
          handler.handle_error(error)
        rescue Uploadcare::Exception::ThrottleError => e
          expect(e.timeout).to eq(10.0)
        end
      end

      it 'defaults timeout to 10.0 when retry-after is zero' do
        error = faraday_error(
          status: 429,
          body: '{"detail":"Throttled"}',
          headers: { 'retry-after' => '0' }
        )
        begin
          handler.handle_error(error)
        rescue Uploadcare::Exception::ThrottleError => e
          expect(e.timeout).to eq(10.0)
        end
      end

      it 'reads Retry-After with capitalized header name' do
        error = faraday_error(
          status: 429,
          body: '{"detail":"Throttled"}',
          headers: { 'Retry-After' => '3' }
        )
        begin
          handler.handle_error(error)
        rescue Uploadcare::Exception::ThrottleError => e
          expect(e.timeout).to eq(3.0)
        end
      end
    end

    context 'with other HTTP status codes' do
      it 'raises RequestError for 500' do
        error = faraday_error(status: 500, body: '{"detail":"Internal error"}')
        expect { handler.handle_error(error) }.to raise_error(
          Uploadcare::Exception::RequestError, 'Internal error'
        )
      end

      it 'raises RequestError for 403' do
        error = faraday_error(status: 403, body: '{"detail":"Forbidden"}')
        expect { handler.handle_error(error) }.to raise_error(
          Uploadcare::Exception::RequestError, 'Forbidden'
        )
      end
    end

    context 'with upload API errors (status 200 with error in body)' do
      it 'raises RequestError when body contains error field' do
        error = faraday_error(
          status: 200,
          body: '{"error":"File is too large."}'
        )
        expect { handler.handle_error(error) }.to raise_error(
          Uploadcare::Exception::RequestError, 'File is too large.'
        )
      end

      it 'does not raise for status 200 without error field' do
        error = faraday_error(
          status: 200,
          body: '{"file":"some-uuid"}'
        )
        expect { handler.handle_error(error) }.to raise_error(
          Uploadcare::Exception::RequestError
        )
      end
    end

    context 'with non-JSON response body' do
      it 'uses raw body as error message' do
        error = faraday_error(status: 500, body: 'Something went wrong')
        expect { handler.handle_error(error) }.to raise_error(
          Uploadcare::Exception::RequestError, 'Something went wrong'
        )
      end

      it 'handles empty body' do
        error = faraday_error(status: 500, body: '')
        expect { handler.handle_error(error) }.to raise_error(
          Uploadcare::Exception::RequestError
        )
      end

      it 'handles nil body' do
        error = faraday_error(status: 500, body: nil)
        expect { handler.handle_error(error) }.to raise_error(
          Uploadcare::Exception::RequestError
        )
      end
    end

    context 'with JSON body without detail key' do
      it 'formats all key-value pairs into the message' do
        error = faraday_error(status: 400, body: '{"field":"is required","name":"cannot be blank"}')
        expect { handler.handle_error(error) }.to raise_error(
          Uploadcare::Exception::InvalidRequestError, 'field: is required; name: cannot be blank'
        )
      end
    end
  end
end

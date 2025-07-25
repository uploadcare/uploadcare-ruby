# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Uploadcare Errors' do
  let(:response) do
    {
      status: 404,
      headers: { 'content-type' => 'application/json' },
      body: { 'error' => 'Not found' }
    }
  end

  let(:request) do
    {
      method: :get,
      url: 'https://api.uploadcare.com/files/123/',
      headers: { 'Authorization' => 'Bearer token' }
    }
  end

  describe Uploadcare::Error do
    subject(:error) { described_class.new('Test error', response, request) }

    it 'inherits from StandardError' do
      expect(error).to be_a(StandardError)
    end

    it 'stores message' do
      expect(error.message).to eq('Test error')
    end

    it 'stores response' do
      expect(error.response).to eq(response)
    end

    it 'stores request' do
      expect(error.request).to eq(request)
    end

    describe '#status' do
      it 'returns status from response' do
        expect(error.status).to eq(404)
      end

      context 'without response' do
        subject(:error) { described_class.new('Test error') }

        it 'returns nil' do
          expect(error.status).to be_nil
        end
      end
    end

    describe '#headers' do
      it 'returns headers from response' do
        expect(error.headers).to eq({ 'content-type' => 'application/json' })
      end

      context 'without response' do
        subject(:error) { described_class.new('Test error') }

        it 'returns nil' do
          expect(error.headers).to be_nil
        end
      end
    end

    describe '#body' do
      it 'returns body from response' do
        expect(error.body).to eq({ 'error' => 'Not found' })
      end

      context 'without response' do
        subject(:error) { described_class.new('Test error') }

        it 'returns nil' do
          expect(error.body).to be_nil
        end
      end
    end
  end

  describe 'Error hierarchy' do
    it 'has correct inheritance structure' do
      # Client errors
      expect(Uploadcare::ClientError.superclass).to eq(Uploadcare::Error)
      expect(Uploadcare::BadRequestError.superclass).to eq(Uploadcare::ClientError)
      expect(Uploadcare::AuthenticationError.superclass).to eq(Uploadcare::ClientError)
      expect(Uploadcare::ForbiddenError.superclass).to eq(Uploadcare::ClientError)
      expect(Uploadcare::NotFoundError.superclass).to eq(Uploadcare::ClientError)
      expect(Uploadcare::MethodNotAllowedError.superclass).to eq(Uploadcare::ClientError)
      expect(Uploadcare::NotAcceptableError.superclass).to eq(Uploadcare::ClientError)
      expect(Uploadcare::RequestTimeoutError.superclass).to eq(Uploadcare::ClientError)
      expect(Uploadcare::ConflictError.superclass).to eq(Uploadcare::ClientError)
      expect(Uploadcare::GoneError.superclass).to eq(Uploadcare::ClientError)
      expect(Uploadcare::UnprocessableEntityError.superclass).to eq(Uploadcare::ClientError)
      expect(Uploadcare::RateLimitError.superclass).to eq(Uploadcare::ClientError)

      # Server errors
      expect(Uploadcare::ServerError.superclass).to eq(Uploadcare::Error)
      expect(Uploadcare::InternalServerError.superclass).to eq(Uploadcare::ServerError)
      expect(Uploadcare::NotImplementedError.superclass).to eq(Uploadcare::ServerError)
      expect(Uploadcare::BadGatewayError.superclass).to eq(Uploadcare::ServerError)
      expect(Uploadcare::ServiceUnavailableError.superclass).to eq(Uploadcare::ServerError)
      expect(Uploadcare::GatewayTimeoutError.superclass).to eq(Uploadcare::ServerError)

      # Network errors
      expect(Uploadcare::NetworkError.superclass).to eq(Uploadcare::Error)
      expect(Uploadcare::ConnectionFailedError.superclass).to eq(Uploadcare::NetworkError)
      expect(Uploadcare::TimeoutError.superclass).to eq(Uploadcare::NetworkError)
      expect(Uploadcare::SSLError.superclass).to eq(Uploadcare::NetworkError)

      # Configuration errors
      expect(Uploadcare::ConfigurationError.superclass).to eq(Uploadcare::Error)
      expect(Uploadcare::InvalidConfigurationError.superclass).to eq(Uploadcare::ConfigurationError)
      expect(Uploadcare::MissingConfigurationError.superclass).to eq(Uploadcare::ConfigurationError)

      # Other errors
      expect(Uploadcare::RequestError.superclass).to eq(Uploadcare::Error)
      expect(Uploadcare::ConversionError.superclass).to eq(Uploadcare::Error)
      expect(Uploadcare::RetryError.superclass).to eq(Uploadcare::Error)

      # Compatibility aliases
      expect(Uploadcare::ThrottleError.superclass).to eq(Uploadcare::RateLimitError)
      expect(Uploadcare::AuthError.superclass).to eq(Uploadcare::AuthenticationError)
    end
  end

  describe Uploadcare::RateLimitError do
    let(:response) do
      {
        status: 429,
        headers: { 'retry-after' => '30' },
        body: { 'error' => 'Rate limit exceeded' }
      }
    end

    subject(:error) { described_class.new('Rate limited', response) }

    describe '#retry_after' do
      it 'returns retry-after header as integer' do
        expect(error.retry_after).to eq(30)
      end

      context 'without retry-after header' do
        let(:response) do
          {
            status: 429,
            headers: {},
            body: { 'error' => 'Rate limit exceeded' }
          }
        end

        it 'returns nil' do
          expect(error.retry_after).to be_nil
        end
      end

      context 'without headers' do
        let(:response) do
          {
            status: 429,
            body: { 'error' => 'Rate limit exceeded' }
          }
        end

        it 'returns nil' do
          expect(error.retry_after).to be_nil
        end
      end
    end
  end

  describe Uploadcare::RequestError do
    describe '.from_response' do
      context 'with 400 status' do
        let(:response) { { status: 400, body: { 'error' => 'Bad request' } } }

        it 'returns BadRequestError' do
          error = described_class.from_response(response)
          expect(error).to be_a(Uploadcare::BadRequestError)
          expect(error.message).to eq('Bad request')
        end
      end

      context 'with 401 status' do
        let(:response) { { status: 401, body: { 'detail' => 'Unauthorized' } } }

        it 'returns AuthenticationError' do
          error = described_class.from_response(response)
          expect(error).to be_a(Uploadcare::AuthenticationError)
          expect(error.message).to eq('Unauthorized')
        end
      end

      context 'with 403 status' do
        let(:response) { { status: 403, body: { 'message' => 'Forbidden' } } }

        it 'returns ForbiddenError' do
          error = described_class.from_response(response)
          expect(error).to be_a(Uploadcare::ForbiddenError)
          expect(error.message).to eq('Forbidden')
        end
      end

      context 'with 404 status' do
        let(:response) { { status: 404, body: 'Not found' } }

        it 'returns NotFoundError' do
          error = described_class.from_response(response)
          expect(error).to be_a(Uploadcare::NotFoundError)
          expect(error.message).to eq('Not found')
        end
      end

      context 'with 429 status' do
        let(:response) { { status: 429, body: { 'error' => 'Too many requests' } } }

        it 'returns RateLimitError' do
          error = described_class.from_response(response)
          expect(error).to be_a(Uploadcare::RateLimitError)
          expect(error.message).to eq('Too many requests')
        end
      end

      context 'with 500 status' do
        let(:response) { { status: 500, body: { 'error' => 'Server error' } } }

        it 'returns InternalServerError' do
          error = described_class.from_response(response)
          expect(error).to be_a(Uploadcare::InternalServerError)
          expect(error.message).to eq('Server error')
        end
      end

      context 'with unmapped 4xx status' do
        let(:response) { { status: 418, body: { 'error' => "I'm a teapot" } } }

        it 'returns generic ClientError' do
          error = described_class.from_response(response)
          expect(error).to be_a(Uploadcare::ClientError)
          expect(error.message).to eq("I'm a teapot")
        end
      end

      context 'with unmapped 5xx status' do
        let(:response) { { status: 599, body: { 'error' => 'Unknown server error' } } }

        it 'returns generic ServerError' do
          error = described_class.from_response(response)
          expect(error).to be_a(Uploadcare::ServerError)
          expect(error.message).to eq('Unknown server error')
        end
      end

      context 'with non-error status' do
        let(:response) { { status: 200, body: { 'success' => true } } }

        it 'returns generic Error' do
          error = described_class.from_response(response)
          expect(error).to be_a(Uploadcare::Error)
          expect(error.message).to eq('HTTP 200')
        end
      end

      context 'with request parameter' do
        let(:response) { { status: 404, body: { 'error' => 'Not found' } } }

        it 'passes request to error' do
          error = described_class.from_response(response, request)
          expect(error.request).to eq(request)
        end
      end

      describe 'message extraction' do
        context 'with error field in body' do
          let(:response) { { status: 400, body: { 'error' => 'Error message' } } }

          it 'uses error field' do
            error = described_class.from_response(response)
            expect(error.message).to eq('Error message')
          end
        end

        context 'with detail field in body' do
          let(:response) { { status: 400, body: { 'detail' => 'Detail message' } } }

          it 'uses detail field' do
            error = described_class.from_response(response)
            expect(error.message).to eq('Detail message')
          end
        end

        context 'with message field in body' do
          let(:response) { { status: 400, body: { 'message' => 'Message field' } } }

          it 'uses message field' do
            error = described_class.from_response(response)
            expect(error.message).to eq('Message field')
          end
        end

        context 'with multiple fields' do
          let(:response) do
            {
              status: 400,
              body: {
                'error' => 'Error field',
                'detail' => 'Detail field',
                'message' => 'Message field'
              }
            }
          end

          it 'prefers error field' do
            error = described_class.from_response(response)
            expect(error.message).to eq('Error field')
          end
        end

        context 'with string body' do
          let(:response) { { status: 400, body: 'String error message' } }

          it 'uses string as message' do
            error = described_class.from_response(response)
            expect(error.message).to eq('String error message')
          end
        end

        context 'with empty string body' do
          let(:response) { { status: 400, body: '' } }

          it 'returns HTTP status message' do
            error = described_class.from_response(response)
            expect(error.message).to eq('HTTP 400')
          end
        end

        context 'with nil body' do
          let(:response) { { status: 400, body: nil } }

          it 'returns HTTP status message' do
            error = described_class.from_response(response)
            expect(error.message).to eq('HTTP 400')
          end
        end

        context 'with non-string/hash body' do
          let(:response) { { status: 400, body: %w[array body] } }

          it 'returns HTTP status message' do
            error = described_class.from_response(response)
            expect(error.message).to eq('HTTP 400')
          end
        end
      end
    end

    describe 'STATUS_ERROR_MAP' do
      it 'has all expected mappings' do
        expect(described_class::STATUS_ERROR_MAP).to eq({
                                                          400 => Uploadcare::BadRequestError,
                                                          401 => Uploadcare::AuthenticationError,
                                                          403 => Uploadcare::ForbiddenError,
                                                          404 => Uploadcare::NotFoundError,
                                                          405 => Uploadcare::MethodNotAllowedError,
                                                          406 => Uploadcare::NotAcceptableError,
                                                          408 => Uploadcare::RequestTimeoutError,
                                                          409 => Uploadcare::ConflictError,
                                                          410 => Uploadcare::GoneError,
                                                          422 => Uploadcare::UnprocessableEntityError,
                                                          429 => Uploadcare::RateLimitError,
                                                          500 => Uploadcare::InternalServerError,
                                                          501 => Uploadcare::NotImplementedError,
                                                          502 => Uploadcare::BadGatewayError,
                                                          503 => Uploadcare::ServiceUnavailableError,
                                                          504 => Uploadcare::GatewayTimeoutError
                                                        })
      end

      it 'is frozen' do
        expect(described_class::STATUS_ERROR_MAP).to be_frozen
      end
    end
  end
end

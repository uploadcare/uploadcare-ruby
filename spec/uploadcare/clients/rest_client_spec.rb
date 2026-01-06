# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::RestClient do
  describe '#get' do
    let(:path) { '/test_endpoint/' }
    let(:params) { { 'param1' => 'value1', 'param2' => 'value2' } }
    let(:headers) { { 'Custom-Header' => 'HeaderValue' } }
    let(:full_url) { "#{Uploadcare.configuration.rest_api_root}#{path}" }

    context 'when the request is successful' do
      let(:response_body) { { 'key' => 'value' } }

      before do
        stub_request(:get, full_url)
          .with(
            query: params
          )
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns the response body parsed as JSON' do
        response = subject.get(path, params, headers)
        expect(response).to eq(response_body)
      end
    end

    context 'when the request returns a 400 Bad Request' do
      before do
        stub_request(:get, full_url)
          .with(query: params)
          .to_return(
            status: 400,
            body: { 'detail' => 'Bad Request' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an InvalidRequestError' do
        expect { subject.get(path, params, headers) }.to raise_error(Uploadcare::Exception::RequestError, 'Bad Request')
      end
    end

    context 'when the request returns a 401 Unauthorized' do
      before do
        stub_request(:get, full_url)
          .to_return(
            status: 401,
            body: { 'detail' => 'Unauthorized' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an AuthenticationError' do
        expect { subject.get(path) }.to raise_error(Uploadcare::Exception::RequestError, 'Unauthorized')
      end
    end

    context 'when the request returns a 403 Forbidden' do
      before do
        stub_request(:get, full_url)
          .to_return(
            status: 403,
            body: { 'detail' => 'Forbidden' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an AuthorizationError' do
        expect { subject.get(path) }.to raise_error(Uploadcare::Exception::RequestError, 'Forbidden')
      end
    end

    context 'when the request returns a 404 Not Found' do
      before do
        stub_request(:get, full_url)
          .to_return(
            status: 404,
            body: { 'detail' => 'Not Found' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises a NotFoundError' do
        expect { subject.get(path) }.to raise_error(Uploadcare::Exception::RequestError, 'Not Found')
      end
    end

    context 'when the request fails with an unexpected error' do
      before do
        stub_request(:get, full_url)
          .to_raise(Uploadcare::Exception::RequestError)
      end

      it 'raises an Uploadcare::Error' do
        expect { subject.get(path) }.to raise_error(Uploadcare::Exception::RequestError)
      end
    end
  end
end

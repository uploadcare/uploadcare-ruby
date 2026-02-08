# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::RestClient do
  let(:client) { described_class.new }

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
        response = client.get(path: path, params: params, headers: headers)
        expect(response).to be_a(Uploadcare::Result)
        expect(response.success).to eq(response_body)
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

      it 'raises a RequestError' do
        result = client.get(path: path, params: params, headers: headers)
        expect(result.failure?).to be true
        expect(result.error).to be_a(Uploadcare::Exception::RequestError)
        expect(result.error.message).to eq('Bad Request')
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

      it 'raises a RequestError' do
        result = client.get(path: path)
        expect(result.failure?).to be true
        expect(result.error).to be_a(Uploadcare::Exception::RequestError)
        expect(result.error.message).to eq('Unauthorized')
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

      it 'raises a RequestError' do
        result = client.get(path: path)
        expect(result.failure?).to be true
        expect(result.error).to be_a(Uploadcare::Exception::RequestError)
        expect(result.error.message).to eq('Forbidden')
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

      it 'raises a RequestError' do
        result = client.get(path: path)
        expect(result.failure?).to be true
        expect(result.error).to be_a(Uploadcare::Exception::RequestError)
        expect(result.error.message).to eq('Not Found')
      end
    end

    context 'when the request fails with an unexpected error' do
      before do
        stub_request(:get, full_url)
          .to_raise(Uploadcare::Exception::RequestError)
      end

      it 'raises an Uploadcare::Error' do
        result = client.get(path: path)
        expect(result.failure?).to be true
        expect(result.error).to be_a(Uploadcare::Exception::RequestError)
      end
    end
  end

  describe '#request' do
    it 'wraps response in Result' do
      allow(client).to receive(:make_request).and_return({ 'ok' => true })

      result = client.request(method: :get, path: '/test')

      expect(result).to be_a(Uploadcare::Result)
      expect(result.success?).to be true
      expect(result.success).to eq({ 'ok' => true })
    end

    it 'captures errors in Result' do
      allow(client).to receive(:make_request).and_raise(StandardError, 'boom')

      result = client.request(method: :get, path: '/test')

      expect(result.failure?).to be true
      expect(result.error_message).to eq('boom')
    end
  end

  describe 'private methods' do
    describe '#apply_request_options' do
      it 'sets timeout options on request' do
        options = Struct.new(:timeout, :open_timeout).new
        request = double('request', options: options)

        client.send(:apply_request_options, request, { timeout: 10, open_timeout: 5 })

        expect(options.timeout).to eq(10)
        expect(options.open_timeout).to eq(5)
      end
    end

    describe '#build_request_uri' do
      it 'returns path as-is for non-GET methods with empty params' do
        path = '/test/path'
        result = client.send(:build_request_uri, path, {}, 'POST')

        expect(result).to eq(path)
      end

      it 'builds URI with query params for GET requests' do
        path = '/test/path'
        params = { 'key' => 'value' }
        result = client.send(:build_request_uri, path, params, 'GET')

        expect(result).to include('key=value')
      end
    end

    describe '#build_uri' do
      it 'returns path as-is when query_params is empty' do
        path = '/test/path'
        result = client.send(:build_uri, path, {})

        expect(result).to eq(path)
      end

      it 'builds URI with query params when provided' do
        path = '/test/path'
        query_params = { 'key' => 'value', 'foo' => 'bar' }
        result = client.send(:build_uri, path, query_params)

        expect(result).to include('key=value')
        expect(result).to include('foo=bar')
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::UploadClient do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'test_public_key',
      secret_key: 'test_secret_key'
    )
  end

  subject(:client) { described_class.new(config) }

  describe '#initialize' do
    it 'initializes with configuration' do
      expect(client).to be_a(described_class)
    end

    it 'uses default configuration when none provided' do
      client = described_class.new
      expect(client).to be_a(described_class)
    end
  end

  describe 'private methods' do
    describe '#connection' do
      it 'creates a Faraday connection with correct base URL' do
        connection = client.send(:connection)
        expect(connection).to be_a(Faraday::Connection)
        expect(connection.url_prefix.to_s).to eq('https://upload.uploadcare.com/')
      end

      it 'configures multipart and json handling' do
        connection = client.send(:connection)
        expect(connection.builder.handlers).to include(Faraday::Request::Multipart)
        expect(connection.builder.handlers).to include(Faraday::Request::UrlEncoded)
      end
    end

    describe '#execute_request' do
      let(:connection) { instance_double(Faraday::Connection) }
      let(:response) { instance_double(Faraday::Response, success?: true, body: { 'result' => 'success' }) }

      before do
        allow(client).to receive(:connection).and_return(connection)
      end

      it 'adds public key to params' do
        expect(connection).to receive(:get).with('/test', hash_including(pub_key: 'test_public_key'), anything).and_return(response)
        client.send(:execute_request, :get, '/test')
      end

      it 'adds user agent header' do
        expect(connection).to receive(:get).with('/test', anything, hash_including('User-Agent' => /Uploadcare Ruby/)).and_return(response)
        client.send(:execute_request, :get, '/test')
      end

      context 'when request succeeds' do
        it 'returns response body' do
          allow(connection).to receive(:get).and_return(response)
          result = client.send(:execute_request, :get, '/test')
          expect(result).to eq({ 'result' => 'success' })
        end
      end

      context 'when request fails' do
        let(:failed_response) { instance_double(Faraday::Response, success?: false, status: 400, body: { 'error' => 'Bad request' }) }

        it 'raises RequestError' do
          allow(connection).to receive(:get).and_return(failed_response)
          expect { client.send(:execute_request, :get, '/test') }.to raise_error(Uploadcare::RequestError, 'Bad request')
        end
      end

      context 'when Faraday error occurs' do
        it 'handles connection errors' do
          allow(connection).to receive(:get).and_raise(Faraday::ConnectionFailed.new('Connection failed'))
          expect { client.send(:execute_request, :get, '/test') }.to raise_error(Uploadcare::RequestError, /Request failed: Connection failed/)
        end
      end
    end

    describe '#user_agent' do
      it 'returns proper user agent string' do
        user_agent = client.send(:user_agent)
        expect(user_agent).to match(%r{Uploadcare Ruby/\d+\.\d+\.\d+ \(Ruby/\d+\.\d+\.\d+\)})
      end
    end
  end
end

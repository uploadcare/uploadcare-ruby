# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Final Coverage for 100%' do
  describe 'UploadClient error paths' do
    let(:client) { Uploadcare::UploadClient.new }

    it 'handles JSON parse errors in handle_response' do
      response = double('response', status: 200, success?: true, body: 'invalid')
      allow(client).to receive(:parse_success_response).and_raise(JSON::ParserError.new('Invalid'))

      result = client.send(:handle_response, response)
      expect(result).to eq({})
    end

    it 'handles Faraday errors with response in handle_response' do
      response = double('response', status: 200, success?: true)
      error = Faraday::ClientError.new('Error')
      allow(error).to receive(:response).and_return({ status: 400, body: 'Bad' })
      allow(client).to receive(:parse_success_response).and_raise(error)

      expect do
        client.send(:handle_response, response)
      end.to raise_error(Uploadcare::Exception::RequestError, /HTTP 400/)
    end

    it 'handles error responses' do
      response = double('response', status: 500, body: 'Error', success?: false)

      expect do
        client.send(:handle_error_response, response)
      end.to raise_error(Uploadcare::Exception::UploadError, /Upload API error/)
    end
  end

  describe 'RestClient path handling' do
    let(:client) { Uploadcare::RestClient.new }

    it 'returns path for non-GET with empty params' do
      result = client.send(:build_request_uri, '/path', {}, 'POST')
      expect(result).to eq('/path')
    end
  end
end

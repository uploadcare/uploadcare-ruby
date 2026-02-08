# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::VideoConverterClient do
  let(:client) { described_class.new }
  let(:rest_api_root) { Uploadcare.configuration.rest_api_root }
  let(:uuid) { SecureRandom.uuid }
  let(:token) { 32_921_143 }

  describe '#convert_video' do
    let(:path) { '/convert/video/' }
    let(:full_url) { "#{rest_api_root}#{path}" }
    let(:video_paths) { ["#{uuid}/video/-/format/mp4/-/quality/lighter/"] }
    let(:options) { { store: '1' } }
    let(:request_body) do
      {
        paths: video_paths,
        store: options[:store]
      }
    end
    let(:response_body) do
      {
        'problems' => {},
        'result' => [
          {
            'original_source' => "#{uuid}/video/-/format/mp4/-/quality/lighter/",
            'token' => 445_630_631,
            'uuid' => 'd52d7136-a2e5-4338-9f45-affbf83b857d',
            'thumbnails_group_uuid' => '575ed4e8-f4e8-4c14-a58b-1527b6d9ee46~1'
          }
        ]
      }
    end

    subject(:result) { client.convert_video(paths: video_paths, options: options) }

    context 'when the request is successful' do
      before do
        stub_request(:post, full_url)
          .with(body: request_body.to_json)
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'sends the correct request' do
        expect(result.success).to eq(response_body)
      end

      it 'returns conversion details' do
        conversion = result.success['result'].first
        expect(conversion['uuid']).to eq('d52d7136-a2e5-4338-9f45-affbf83b857d')
        expect(conversion['token']).to eq(445_630_631)
        expect(conversion['thumbnails_group_uuid']).to eq('575ed4e8-f4e8-4c14-a58b-1527b6d9ee46~1')
      end
    end

    context 'when the request fails' do
      before do
        stub_request(:post, full_url)
          .with(body: request_body.to_json)
          .to_return(
            status: 400,
            body: { 'detail' => 'Invalid request' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an InvalidRequestError' do
        expect(result.failure?).to be true
        expect(result.error).to be_a(Uploadcare::Exception::RequestError)
        expect(result.error.message).to eq('Invalid request')
      end
    end
  end

  describe '#status' do
    let(:path) { "/convert/video/status/#{token}/" }
    let(:full_url) { "#{rest_api_root}#{path}" }
    let(:response_body) do
      {
        'status' => 'processing',
        'error' => nil,
        'result' => {
          'uuid' => 'd52d7136-a2e5-4338-9f45-affbf83b857d',
          'thumbnails_group_uuid' => '575ed4e8-f4e8-4c14-a58b-1527b6d9ee46~1'
        }
      }
    end

    subject(:result) { client.status(token: token) }

    context 'when the request is successful' do
      before do
        stub_request(:get, full_url)
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns the job status' do
        expect(result.success['status']).to eq('processing')
        expect(result.success['result']['uuid']).to eq('d52d7136-a2e5-4338-9f45-affbf83b857d')
        expect(result.success['result']['thumbnails_group_uuid']).to eq('575ed4e8-f4e8-4c14-a58b-1527b6d9ee46~1')
      end
    end

    context 'when the request fails' do
      before do
        stub_request(:get, full_url)
          .to_return(
            status: 404,
            body: { 'detail' => 'Job not found' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises a NotFoundError' do
        expect(result.failure?).to be true
        expect(result.error).to be_a(Uploadcare::Exception::RequestError)
        expect(result.error.message).to eq('Job not found')
      end
    end
  end
end

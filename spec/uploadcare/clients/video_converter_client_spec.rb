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

    subject { client.convert_video(video_paths, options) }

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
        expect(subject).to eq(response_body)
      end

      it 'returns conversion details' do
        result = subject['result'].first
        expect(result['uuid']).to eq('d52d7136-a2e5-4338-9f45-affbf83b857d')
        expect(result['token']).to eq(445_630_631)
        expect(result['thumbnails_group_uuid']).to eq('575ed4e8-f4e8-4c14-a58b-1527b6d9ee46~1')
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
        expect { subject }.to raise_error(Uploadcare::Exception::RequestError, 'Invalid request')
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

    subject { client.status(token) }

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
        expect(subject['status']).to eq('processing')
        expect(subject['result']['uuid']).to eq('d52d7136-a2e5-4338-9f45-affbf83b857d')
        expect(subject['result']['thumbnails_group_uuid']).to eq('575ed4e8-f4e8-4c14-a58b-1527b6d9ee46~1')
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
        expect { subject }.to raise_error(Uploadcare::Exception::RequestError, 'Job not found')
      end
    end
  end
end

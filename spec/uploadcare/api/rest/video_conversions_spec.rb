# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Api::Rest::VideoConversions do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end
  let(:file_uuid) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }

  let(:rest) { Uploadcare::Api::Rest.new(config: config) }

  subject(:video_conversions) { described_class.new(rest: rest) }

  describe '#initialize' do
    it 'stores the rest client' do
      expect(video_conversions.rest).to eq(rest)
    end
  end

  describe '#convert' do
    let(:conversion_path) { "#{file_uuid}/video/-/format/mp4/-/quality/normal/" }

    before do
      stub_request(:post, 'https://api.uploadcare.com/convert/video/')
        .to_return(
          status: 200,
          body: {
            result: [
              { original_source: file_uuid, token: 67_890, uuid: 'converted-video-uuid' }
            ],
            problems: {}
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'converts a video and returns the result' do
      result = video_conversions.convert(paths: [conversion_path])

      expect(result).to be_success
      expect(result.value!['result'].first['token']).to eq(67_890)
      expect(result.value!['problems']).to eq({})
    end

    it 'sends paths in the request body' do
      stub = stub_request(:post, 'https://api.uploadcare.com/convert/video/')
             .with(body: hash_including('paths' => [conversion_path]))
             .to_return(
               status: 200,
               body: { result: [], problems: {} }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      video_conversions.convert(paths: [conversion_path])

      expect(stub).to have_been_requested
    end

    it 'merges additional options like store' do
      stub = stub_request(:post, 'https://api.uploadcare.com/convert/video/')
             .with(body: hash_including('paths' => [conversion_path], 'store' => '1'))
             .to_return(
               status: 200,
               body: { result: [], problems: {} }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      video_conversions.convert(paths: [conversion_path], options: { store: '1' })

      expect(stub).to have_been_requested
    end

    it 'normalizes boolean store values' do
      stub = stub_request(:post, 'https://api.uploadcare.com/convert/video/')
             .with(body: hash_including('paths' => [conversion_path], 'store' => '1'))
             .to_return(
               status: 200,
               body: { result: [], problems: {} }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      video_conversions.convert(paths: [conversion_path], options: { store: true })

      expect(stub).to have_been_requested
    end

    it 'returns a failure Result on error' do
      stub_request(:post, 'https://api.uploadcare.com/convert/video/')
        .to_return(
          status: 400,
          body: { detail: 'Invalid conversion path.' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = video_conversions.convert(paths: ['invalid-path'])

      expect(result).to be_failure
      expect(result.error).to be_a(Uploadcare::Exception::InvalidRequestError)
    end
  end

  describe '#status' do
    let(:token) { 67_890 }

    before do
      stub_request(:get, "https://api.uploadcare.com/convert/video/status/#{token}/")
        .to_return(
          status: 200,
          body: {
            status: 'finished',
            result: { uuid: 'converted-video-uuid', thumbnails_group_uuid: 'thumb-group-uuid' },
            error: nil
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns the video conversion job status' do
      result = video_conversions.status(token: token)

      expect(result).to be_success
      expect(result.value!['status']).to eq('finished')
      expect(result.value!['result']['uuid']).to eq('converted-video-uuid')
    end

    it 'handles processing status' do
      stub_request(:get, "https://api.uploadcare.com/convert/video/status/#{token}/")
        .to_return(
          status: 200,
          body: { status: 'processing', result: nil, error: nil }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = video_conversions.status(token: token)

      expect(result).to be_success
      expect(result.value!['status']).to eq('processing')
    end

    it 'handles error status' do
      stub_request(:get, "https://api.uploadcare.com/convert/video/status/#{token}/")
        .to_return(
          status: 200,
          body: { status: 'failed', result: nil, error: 'Conversion failed' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = video_conversions.status(token: token)

      expect(result).to be_success
      expect(result.value!['status']).to eq('failed')
      expect(result.value!['error']).to eq('Conversion failed')
    end
  end
end

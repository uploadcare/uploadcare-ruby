# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Resources::VideoConversion do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end
  let(:client) { Uploadcare::Client.new(config: config) }
  let(:rest) { instance_double(Uploadcare::Api::Rest) }
  let(:rest_video_conversions) { double('video_conversions') }
  let(:api) { instance_double(Uploadcare::Client::Api, rest: rest) }

  let(:file_uuid) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }

  before do
    allow(client).to receive(:api).and_return(api)
    allow(rest).to receive(:video_conversions).and_return(rest_video_conversions)
  end

  describe '.convert' do
    it 'converts a video to the specified format and quality' do
      conversion_response = {
        'result' => [{ 'uuid' => 'converted-uuid', 'token' => 'job-token-123' }],
        'problems' => {}
      }

      allow(rest_video_conversions).to receive(:convert)
        .with(
          paths: ["#{file_uuid}/video/-/format/mp4/-/quality/best/"],
          options: {},
          request_options: {}
        )
        .and_return(Uploadcare::Result.success(conversion_response))

      result = described_class.convert(
        params: { uuid: file_uuid, format: 'mp4', quality: 'best' },
        client: client
      )
      expect(result).to be_a(described_class)
    end

    it 'raises ArgumentError when uuid is missing' do
      expect {
        described_class.convert(params: { format: 'mp4', quality: 'best' }, client: client)
      }.to raise_error(ArgumentError, 'params must include :uuid')
    end

    it 'raises ArgumentError when format is missing' do
      expect {
        described_class.convert(params: { uuid: file_uuid, quality: 'best' }, client: client)
      }.to raise_error(ArgumentError, 'params must include :format')
    end

    it 'raises ArgumentError when quality is missing' do
      expect {
        described_class.convert(params: { uuid: file_uuid, format: 'mp4' }, client: client)
      }.to raise_error(ArgumentError, 'params must include :quality')
    end

    it 'handles multiple UUIDs' do
      uuids = %w[uuid-1 uuid-2]
      conversion_response = { 'result' => [], 'problems' => {} }

      allow(rest_video_conversions).to receive(:convert)
        .with(
          paths: [
            'uuid-1/video/-/format/webm/-/quality/normal/',
            'uuid-2/video/-/format/webm/-/quality/normal/'
          ],
          options: {},
          request_options: {}
        )
        .and_return(Uploadcare::Result.success(conversion_response))

      described_class.convert(
        params: { uuid: uuids, format: 'webm', quality: 'normal' },
        client: client
      )
    end

    it 'passes options through' do
      allow(rest_video_conversions).to receive(:convert)
        .with(
          paths: ["#{file_uuid}/video/-/format/mp4/-/quality/best/"],
          options: { store: true },
          request_options: {}
        )
        .and_return(Uploadcare::Result.success({ 'result' => [], 'problems' => {} }))

      described_class.convert(
        params: { uuid: file_uuid, format: 'mp4', quality: 'best' },
        options: { store: true },
        client: client
      )
    end
  end

  describe '#fetch_status' do
    it 'fetches conversion job status' do
      conversion = described_class.new({}, client)
      status_response = {
        'status' => 'finished',
        'result' => [{ 'uuid' => 'converted-uuid' }],
        'error' => nil
      }

      allow(rest_video_conversions).to receive(:status)
        .with(token: 'job-token-123', request_options: {})
        .and_return(Uploadcare::Result.success(status_response))

      result = conversion.fetch_status(token: 'job-token-123')
      expect(result).to eq(conversion)
      expect(conversion.status).to eq('finished')
      expect(conversion.result).to eq([{ 'uuid' => 'converted-uuid' }])
    end
  end

  describe 'attributes' do
    it 'exposes problems, status, error, and result' do
      conversion = described_class.new(
        { 'problems' => {}, 'status' => 'processing', 'error' => nil, 'result' => [] },
        client
      )
      expect(conversion.problems).to eq({})
      expect(conversion.status).to eq('processing')
      expect(conversion.error).to be_nil
      expect(conversion.result).to eq([])
    end
  end
end

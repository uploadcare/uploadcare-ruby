# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::VideoConverter do
  let(:uuid) { SecureRandom.uuid }
  let(:token) { '32921143' }
  subject(:video_converter) { described_class.new }

  describe '#convert' do
    let(:video_params) { { uuid: 'video_uuid', format: :mp4, quality: :lighter } }
    let(:options) { { store: true } }
    let(:response_body) do
      {
        'problems' => {},
        'result' => [
          {
            'original_source' => 'video_uuid/video/-/format/mp4/-/quality/lighter/',
            'token' => 445_630_631,
            'uuid' => 'd52d7136-a2e5-4338-9f45-affbf83b857d',
            'thumbnails_group_uuid' => '575ed4e8-f4e8-4c14-a58b-1527b6d9ee46~1'
          }
        ]
      }
    end

    subject { described_class.convert(video_params, options) }

    before do
      allow_any_instance_of(Uploadcare::VideoConverterClient).to receive(:convert_video)
        .with(['video_uuid/video/-/format/mp4/-/quality/lighter/'], options).and_return(response_body)
    end

    it { is_expected.to eq(response_body) }

    it 'returns the correct conversion details' do
      result = subject['result'].first
      expect(result['uuid']).to eq('d52d7136-a2e5-4338-9f45-affbf83b857d')
      expect(result['token']).to eq(445_630_631)
      expect(result['thumbnails_group_uuid']).to eq('575ed4e8-f4e8-4c14-a58b-1527b6d9ee46~1')
    end
  end

  describe '#status' do
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

    subject { video_converter.status(token) }

    before do
      allow_any_instance_of(Uploadcare::VideoConverterClient).to receive(:status).with(token).and_return(response_body)
    end

    it 'returns an instance of VideoConverter' do
      result = video_converter.fetch_status(token)
      expect(result).to be_a(Uploadcare::VideoConverter)
    end

    it 'assigns attributes correctly' do
      result = video_converter.fetch_status(token)
      expect(result.status).to eq('processing')
      expect(result.result['uuid']).to eq('d52d7136-a2e5-4338-9f45-affbf83b857d')
      expect(result.result['thumbnails_group_uuid']).to eq('575ed4e8-f4e8-4c14-a58b-1527b6d9ee46~1')
    end
  end
end

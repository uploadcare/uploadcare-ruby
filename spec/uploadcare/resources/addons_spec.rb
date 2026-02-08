# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Addons do
  let(:uuid) { '1bac376c-aa7e-4356-861b-dd2657b5bfd2' }
  let(:request_id) { 'd1fb31c6-ed34-4e21-bdc3-4f1485f58e21' }
  let(:addons_client) { instance_double(Uploadcare::AddonsClient) }

  before do
    allow(described_class).to receive(:addons_client).and_return(addons_client)
  end

  describe '.aws_rekognition_detect_labels' do
    let(:response_body) { { 'request_id' => '8db3c8b4-2dea-4146-bcdb-63387e2b33c1' } }

    before do
      allow(addons_client).to receive(:aws_rekognition_detect_labels)
        .with(uuid: uuid, request_options: {})
        .and_return(response_body)
    end

    it 'returns an instance of Addons and assigns the request_id' do
      result = described_class.aws_rekognition_detect_labels(uuid: uuid)
      expect(result).to be_a(described_class)
      expect(result.request_id).to eq('8db3c8b4-2dea-4146-bcdb-63387e2b33c1')
    end

    it 'raises when the client returns a failure' do
      allow(addons_client).to receive(:aws_rekognition_detect_labels)
        .and_return(Uploadcare::Result.failure(Uploadcare::Exception::RequestError.new('Bad Request')))

      expect { described_class.aws_rekognition_detect_labels(uuid: uuid) }
        .to raise_error(Uploadcare::Exception::RequestError, 'Bad Request')
    end
  end

  describe '.aws_rekognition_detect_labels_status' do
    let(:response_body) { { 'status' => 'in_progress' } }

    before do
      allow(addons_client).to receive(:aws_rekognition_detect_labels_status)
        .with(request_id: request_id, request_options: {})
        .and_return(response_body)
    end

    it 'returns an instance of Addons and assigns the status' do
      result = described_class.aws_rekognition_detect_labels_status(request_id: request_id)
      expect(result).to be_a(described_class)
      expect(result.status).to eq('in_progress')
    end
  end

  describe '.aws_rekognition_detect_moderation_labels' do
    let(:response_body) { { 'request_id' => '8db3c8b4-2dea-4146-bcdb-63387e2b33c1' } }

    before do
      allow(addons_client).to receive(:aws_rekognition_detect_moderation_labels)
        .with(uuid: uuid, request_options: {})
        .and_return(response_body)
    end

    it 'returns an instance of Addons and assigns the request_id' do
      result = described_class.aws_rekognition_detect_moderation_labels(uuid: uuid)
      expect(result).to be_a(described_class)
      expect(result.request_id).to eq(response_body['request_id'])
    end
  end

  describe '.aws_rekognition_detect_moderation_labels_status' do
    let(:response_body) { { 'status' => 'in_progress' } }

    before do
      allow(addons_client).to receive(:aws_rekognition_detect_moderation_labels_status)
        .with(request_id: request_id, request_options: {})
        .and_return(response_body)
    end

    it 'returns an instance of Addons and assigns the status' do
      result = described_class.aws_rekognition_detect_moderation_labels_status(request_id: request_id)
      expect(result).to be_a(described_class)
      expect(result.status).to eq('in_progress')
    end
  end

  describe '.uc_clamav_virus_scan' do
    let(:params) { { purge_infected: true } }
    let(:response_body) { { 'request_id' => '8db3c8b4-2dea-4146-bcdb-63387e2b33c1' } }

    before do
      allow(addons_client).to receive(:uc_clamav_virus_scan)
        .with(uuid: uuid, params: params, request_options: {})
        .and_return(response_body)
    end

    it 'returns an instance of Addons and assigns the request_id' do
      result = described_class.uc_clamav_virus_scan(uuid: uuid, params: params)
      expect(result).to be_a(described_class)
      expect(result.request_id).to eq('8db3c8b4-2dea-4146-bcdb-63387e2b33c1')
    end
  end

  describe '.uc_clamav_virus_scan_status' do
    let(:response_body) { { 'status' => 'in_progress' } }

    before do
      allow(addons_client).to receive(:uc_clamav_virus_scan_status)
        .with(request_id: request_id, request_options: {})
        .and_return(response_body)
    end

    it 'returns an instance of Addons and assigns the status' do
      result = described_class.uc_clamav_virus_scan_status(request_id: request_id)
      expect(result).to be_a(described_class)
      expect(result.status).to eq('in_progress')
    end
  end

  describe '.remove_bg' do
    let(:params) { { crop: true, type_level: '2' } }
    let(:response_body) { { 'request_id' => '8db3c8b4-2dea-4146-bcdb-63387e2b33c1' } }

    before do
      allow(addons_client).to receive(:remove_bg)
        .with(uuid: uuid, params: params, request_options: {})
        .and_return(response_body)
    end

    it 'returns an instance of Addons and assigns the request_id' do
      result = described_class.remove_bg(uuid: uuid, params: params)
      expect(result).to be_a(described_class)
      expect(result.request_id).to eq('8db3c8b4-2dea-4146-bcdb-63387e2b33c1')
    end
  end

  describe '.remove_bg_status' do
    let(:response_body) { { 'status' => 'done', 'result' => { 'file_id' => '21975c81-7f57-4c7a-aef9-acfe28779f78' } } }

    before do
      allow(addons_client).to receive(:remove_bg_status)
        .with(request_id: request_id, request_options: {})
        .and_return(response_body)
    end

    it 'returns an instance of Addons and assigns the status and result' do
      result = described_class.remove_bg_status(request_id: request_id)
      expect(result).to be_a(described_class)
      expect(result.status).to eq('done')
      expect(result.result['file_id']).to eq('21975c81-7f57-4c7a-aef9-acfe28779f78')
    end
  end

  describe 'private methods' do
    describe '.addons_client' do
      it 'memoizes the client instance' do
        # Remove the mock to test actual memoization
        allow(described_class).to receive(:addons_client).and_call_original

        config = Uploadcare.configuration
        client1 = described_class.send(:addons_client, config)
        client2 = described_class.send(:addons_client, config)

        expect(client1).to be_a(Uploadcare::AddonsClient)
        expect(client1).to equal(client2) # Same object instance
      end
    end
  end
end

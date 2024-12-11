# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::AddOns do
  let(:uuid) { '1bac376c-aa7e-4356-861b-dd2657b5bfd2' }
  let(:request_id) { 'd1fb31c6-ed34-4e21-bdc3-4f1485f58e21' }
  let(:add_ons_client) { instance_double(Uploadcare::AddOnsClient) }

  before do
    allow(described_class).to receive(:add_ons_client).and_return(add_ons_client)
  end

  describe '.aws_rekognition_detect_labels' do
    let(:response_body) { { 'request_id' => '8db3c8b4-2dea-4146-bcdb-63387e2b33c1' } }

    before do
      allow(add_ons_client).to receive(:aws_rekognition_detect_labels).with(uuid).and_return(response_body)
    end

    it 'returns an instance of AddOns and assigns the request_id' do
      result = described_class.aws_rekognition_detect_labels(uuid)
      expect(result).to be_a(described_class)
      expect(result.request_id).to eq('8db3c8b4-2dea-4146-bcdb-63387e2b33c1')
    end
  end

  describe '.aws_rekognition_detect_labels_status' do
    let(:response_body) { { 'status' => 'in_progress' } }

    before do
      allow(add_ons_client).to receive(:aws_rekognition_detect_labels_status).with(request_id).and_return(response_body)
    end

    it 'returns an instance of AddOns and assigns the status' do
      result = described_class.aws_rekognition_detect_labels_status(request_id)
      expect(result).to be_a(described_class)
      expect(result.status).to eq('in_progress')
    end
  end

  describe '.aws_rekognition_detect_moderation_labels' do
    let(:response_body) { { 'request_id' => '8db3c8b4-2dea-4146-bcdb-63387e2b33c1' } }

    before do
      allow(add_ons_client).to receive(:aws_rekognition_detect_moderation_labels).with(uuid).and_return(response_body)
    end

    it 'returns an instance of AddOns and assigns the request_id' do
      result = described_class.aws_rekognition_detect_moderation_labels(uuid)
      expect(result).to be_a(described_class)
      expect(result.request_id).to eq(response_body['request_id'])
    end
  end

  describe '.check_aws_rekognition_detect_moderation_labels_status' do
    let(:response_body) { { 'status' => 'in_progress' } }

    before do
      allow(add_ons_client).to receive(:aws_rekognition_detect_moderation_labels_status).with(request_id).and_return(response_body)
    end

    it 'returns an instance of AddOns and assigns the status' do
      result = described_class.check_aws_rekognition_detect_moderation_labels_status(request_id)
      expect(result).to be_a(described_class)
      expect(result.status).to eq('in_progress')
    end
  end

  describe '.uc_clamav_virus_scan' do
    let(:params) { { purge_infected: true } }
    let(:response_body) { { 'request_id' => '8db3c8b4-2dea-4146-bcdb-63387e2b33c1' } }

    before do
      allow(add_ons_client).to receive(:uc_clamav_virus_scan).with(uuid, params).and_return(response_body)
    end

    it 'returns an instance of AddOns and assigns the request_id' do
      result = described_class.uc_clamav_virus_scan(uuid, params)
      expect(result).to be_a(described_class)
      expect(result.request_id).to eq('8db3c8b4-2dea-4146-bcdb-63387e2b33c1')
    end
  end

  describe '.uc_clamav_virus_scan_status' do
    let(:response_body) { { 'status' => 'in_progress' } }

    before do
      allow(add_ons_client).to receive(:uc_clamav_virus_scan_status).with(request_id).and_return(response_body)
    end

    it 'returns an instance of AddOns and assigns the status' do
      result = described_class.uc_clamav_virus_scan_status(request_id)
      expect(result).to be_a(described_class)
      expect(result.status).to eq('in_progress')
    end
  end

  describe '.remove_bg' do
    let(:params) { { crop: true, type_level: '2' } }
    let(:response_body) { { 'request_id' => '8db3c8b4-2dea-4146-bcdb-63387e2b33c1' } }

    before do
      allow(add_ons_client).to receive(:remove_bg).with(uuid, params).and_return(response_body)
    end

    it 'returns an instance of AddOns and assigns the request_id' do
      result = described_class.remove_bg(uuid, params)
      expect(result).to be_a(described_class)
      expect(result.request_id).to eq('8db3c8b4-2dea-4146-bcdb-63387e2b33c1')
    end
  end

  describe '.remove_bg_status' do
    let(:response_body) { { 'status' => 'done', 'result' => { 'file_id' => '21975c81-7f57-4c7a-aef9-acfe28779f78' } } }

    before do
      allow(add_ons_client).to receive(:remove_bg_status).with(request_id).and_return(response_body)
    end

    it 'returns an instance of AddOns and assigns the status and result' do
      result = described_class.remove_bg_status(request_id)
      expect(result).to be_a(described_class)
      expect(result.status).to eq('done')
      expect(result.result['file_id']).to eq('21975c81-7f57-4c7a-aef9-acfe28779f78')
    end
  end
end

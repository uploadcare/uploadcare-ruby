# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Resources::AddonExecution do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end
  let(:client) { Uploadcare::Client.new(config: config) }
  let(:rest) { instance_double(Uploadcare::Api::Rest) }
  let(:rest_addons) { instance_double(Uploadcare::Api::Rest::Addons) }
  let(:api) { instance_double(Uploadcare::Client::Api, rest: rest) }

  let(:file_uuid) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }
  let(:request_id) { 'req-abc-123' }
  let(:execute_response) { { 'request_id' => request_id } }
  let(:status_response) { { 'status' => 'done', 'result' => { 'labels' => [] } } }

  before do
    allow(client).to receive(:api).and_return(api)
    allow(rest).to receive(:addons).and_return(rest_addons)
  end

  describe '.aws_rekognition_detect_labels' do
    it 'executes label detection and returns an AddonExecution' do
      allow(rest_addons).to receive(:aws_rekognition_detect_labels)
        .with(uuid: file_uuid, request_options: {})
        .and_return(Uploadcare::Result.success(execute_response))

      result = described_class.aws_rekognition_detect_labels(uuid: file_uuid, client: client)
      expect(result).to be_a(described_class)
      expect(result.request_id).to eq(request_id)
    end
  end

  describe '.aws_rekognition_detect_labels_status' do
    it 'checks label detection status' do
      allow(rest_addons).to receive(:aws_rekognition_detect_labels_status)
        .with(request_id: request_id, request_options: {})
        .and_return(Uploadcare::Result.success(status_response))

      result = described_class.aws_rekognition_detect_labels_status(request_id: request_id, client: client)
      expect(result).to be_a(described_class)
      expect(result.status).to eq('done')
    end
  end

  describe '.aws_rekognition_detect_moderation_labels' do
    it 'executes moderation label detection' do
      allow(rest_addons).to receive(:aws_rekognition_detect_moderation_labels)
        .with(uuid: file_uuid, request_options: {})
        .and_return(Uploadcare::Result.success(execute_response))

      result = described_class.aws_rekognition_detect_moderation_labels(uuid: file_uuid, client: client)
      expect(result).to be_a(described_class)
      expect(result.request_id).to eq(request_id)
    end
  end

  describe '.aws_rekognition_detect_moderation_labels_status' do
    it 'checks moderation label detection status' do
      allow(rest_addons).to receive(:aws_rekognition_detect_moderation_labels_status)
        .with(request_id: request_id, request_options: {})
        .and_return(Uploadcare::Result.success(status_response))

      result = described_class.aws_rekognition_detect_moderation_labels_status(
        request_id: request_id, client: client
      )
      expect(result).to be_a(described_class)
      expect(result.status).to eq('done')
    end
  end

  describe '.uc_clamav_virus_scan' do
    it 'executes virus scan with optional params' do
      allow(rest_addons).to receive(:uc_clamav_virus_scan)
        .with(uuid: file_uuid, params: { purge_infected: true }, request_options: {})
        .and_return(Uploadcare::Result.success(execute_response))

      result = described_class.uc_clamav_virus_scan(
        uuid: file_uuid, params: { purge_infected: true }, client: client
      )
      expect(result).to be_a(described_class)
      expect(result.request_id).to eq(request_id)
    end

    it 'defaults params to empty hash' do
      allow(rest_addons).to receive(:uc_clamav_virus_scan)
        .with(uuid: file_uuid, params: {}, request_options: {})
        .and_return(Uploadcare::Result.success(execute_response))

      result = described_class.uc_clamav_virus_scan(uuid: file_uuid, client: client)
      expect(result).to be_a(described_class)
    end
  end

  describe '.uc_clamav_virus_scan_status' do
    it 'checks virus scan status' do
      allow(rest_addons).to receive(:uc_clamav_virus_scan_status)
        .with(request_id: request_id, request_options: {})
        .and_return(Uploadcare::Result.success(status_response))

      result = described_class.uc_clamav_virus_scan_status(request_id: request_id, client: client)
      expect(result).to be_a(described_class)
      expect(result.status).to eq('done')
    end
  end

  describe '.remove_bg' do
    it 'executes background removal with optional params' do
      allow(rest_addons).to receive(:remove_bg)
        .with(uuid: file_uuid, params: { type: 'auto' }, request_options: {})
        .and_return(Uploadcare::Result.success(execute_response))

      result = described_class.remove_bg(uuid: file_uuid, params: { type: 'auto' }, client: client)
      expect(result).to be_a(described_class)
      expect(result.request_id).to eq(request_id)
    end

    it 'defaults params to empty hash' do
      allow(rest_addons).to receive(:remove_bg)
        .with(uuid: file_uuid, params: {}, request_options: {})
        .and_return(Uploadcare::Result.success(execute_response))

      result = described_class.remove_bg(uuid: file_uuid, client: client)
      expect(result).to be_a(described_class)
    end
  end

  describe '.remove_bg_status' do
    it 'checks background removal status' do
      allow(rest_addons).to receive(:remove_bg_status)
        .with(request_id: request_id, request_options: {})
        .and_return(Uploadcare::Result.success(status_response))

      result = described_class.remove_bg_status(request_id: request_id, client: client)
      expect(result).to be_a(described_class)
      expect(result.status).to eq('done')
    end
  end

  describe 'attributes' do
    it 'exposes request_id, status, and result' do
      addon = described_class.new(
        { 'request_id' => request_id, 'status' => 'in_progress', 'result' => nil },
        client
      )
      expect(addon.request_id).to eq(request_id)
      expect(addon.status).to eq('in_progress')
      expect(addon.result).to be_nil
    end
  end
end

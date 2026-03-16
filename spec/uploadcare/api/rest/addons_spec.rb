# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Api::Rest::Addons do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end

  let(:rest) { Uploadcare::Api::Rest.new(config: config) }

  subject(:addons) { described_class.new(rest: rest) }

  let(:file_uuid) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }
  let(:request_id) { 'req-abc-123' }

  describe '#initialize' do
    it 'stores the rest client' do
      expect(addons.rest).to eq(rest)
    end
  end

  describe '#aws_rekognition_detect_labels' do
    before do
      stub_request(:post, 'https://api.uploadcare.com/addons/aws_rekognition_detect_labels/execute/')
        .to_return(
          status: 200,
          body: { request_id: request_id }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'executes label detection and returns a request_id' do
      result = addons.aws_rekognition_detect_labels(uuid: file_uuid)

      expect(result).to be_success
      expect(result.value!['request_id']).to eq(request_id)
    end

    it 'sends the file UUID as the target parameter' do
      stub = stub_request(:post, 'https://api.uploadcare.com/addons/aws_rekognition_detect_labels/execute/')
        .with(body: hash_including('target' => file_uuid))
        .to_return(
          status: 200,
          body: { request_id: request_id }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      addons.aws_rekognition_detect_labels(uuid: file_uuid)

      expect(stub).to have_been_requested
    end
  end

  describe '#aws_rekognition_detect_labels_status' do
    before do
      stub_request(:get, 'https://api.uploadcare.com/addons/aws_rekognition_detect_labels/execute/status/')
        .with(query: { request_id: request_id })
        .to_return(
          status: 200,
          body: { status: 'done', result: { labels: [{ name: 'Cat', confidence: 99.5 }] } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns the status of label detection' do
      result = addons.aws_rekognition_detect_labels_status(request_id: request_id)

      expect(result).to be_success
      expect(result.value!['status']).to eq('done')
    end
  end

  describe '#aws_rekognition_detect_moderation_labels' do
    before do
      stub_request(:post, 'https://api.uploadcare.com/addons/aws_rekognition_detect_moderation_labels/execute/')
        .to_return(
          status: 200,
          body: { request_id: request_id }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'executes moderation label detection and returns a request_id' do
      result = addons.aws_rekognition_detect_moderation_labels(uuid: file_uuid)

      expect(result).to be_success
      expect(result.value!['request_id']).to eq(request_id)
    end

    it 'sends the file UUID as the target parameter' do
      stub = stub_request(:post, 'https://api.uploadcare.com/addons/aws_rekognition_detect_moderation_labels/execute/')
        .with(body: hash_including('target' => file_uuid))
        .to_return(
          status: 200,
          body: { request_id: request_id }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      addons.aws_rekognition_detect_moderation_labels(uuid: file_uuid)

      expect(stub).to have_been_requested
    end
  end

  describe '#aws_rekognition_detect_moderation_labels_status' do
    before do
      stub_request(:get, 'https://api.uploadcare.com/addons/aws_rekognition_detect_moderation_labels/execute/status/')
        .with(query: { request_id: request_id })
        .to_return(
          status: 200,
          body: { status: 'done', result: { moderation_labels: [] } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns the status of moderation label detection' do
      result = addons.aws_rekognition_detect_moderation_labels_status(request_id: request_id)

      expect(result).to be_success
      expect(result.value!['status']).to eq('done')
    end
  end

  describe '#uc_clamav_virus_scan' do
    before do
      stub_request(:post, 'https://api.uploadcare.com/addons/uc_clamav_virus_scan/execute/')
        .to_return(
          status: 200,
          body: { request_id: request_id }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'executes a ClamAV virus scan and returns a request_id' do
      result = addons.uc_clamav_virus_scan(uuid: file_uuid)

      expect(result).to be_success
      expect(result.value!['request_id']).to eq(request_id)
    end

    it 'sends the file UUID as the target parameter' do
      stub = stub_request(:post, 'https://api.uploadcare.com/addons/uc_clamav_virus_scan/execute/')
        .with(body: hash_including('target' => file_uuid))
        .to_return(
          status: 200,
          body: { request_id: request_id }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      addons.uc_clamav_virus_scan(uuid: file_uuid)

      expect(stub).to have_been_requested
    end

    it 'merges additional params' do
      stub = stub_request(:post, 'https://api.uploadcare.com/addons/uc_clamav_virus_scan/execute/')
        .with(body: hash_including('target' => file_uuid, 'purge_infected' => true))
        .to_return(
          status: 200,
          body: { request_id: request_id }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      addons.uc_clamav_virus_scan(uuid: file_uuid, params: { purge_infected: true })

      expect(stub).to have_been_requested
    end
  end

  describe '#uc_clamav_virus_scan_status' do
    before do
      stub_request(:get, 'https://api.uploadcare.com/addons/uc_clamav_virus_scan/execute/status/')
        .with(query: { request_id: request_id })
        .to_return(
          status: 200,
          body: { status: 'done', result: { infected: false } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns the status of a ClamAV scan' do
      result = addons.uc_clamav_virus_scan_status(request_id: request_id)

      expect(result).to be_success
      expect(result.value!['status']).to eq('done')
      expect(result.value!['result']['infected']).to be false
    end
  end

  describe '#remove_bg' do
    before do
      stub_request(:post, 'https://api.uploadcare.com/addons/remove_bg/execute/')
        .to_return(
          status: 200,
          body: { request_id: request_id }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'executes background removal and returns a request_id' do
      result = addons.remove_bg(uuid: file_uuid)

      expect(result).to be_success
      expect(result.value!['request_id']).to eq(request_id)
    end

    it 'sends the target and params in the request body' do
      stub = stub_request(:post, 'https://api.uploadcare.com/addons/remove_bg/execute/')
        .with(body: hash_including('target' => file_uuid, 'params' => { 'crop' => true }))
        .to_return(
          status: 200,
          body: { request_id: request_id }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      addons.remove_bg(uuid: file_uuid, params: { crop: true })

      expect(stub).to have_been_requested
    end
  end

  describe '#remove_bg_status' do
    before do
      stub_request(:get, 'https://api.uploadcare.com/addons/remove_bg/execute/status/')
        .with(query: { request_id: request_id })
        .to_return(
          status: 200,
          body: { status: 'done', result: { uuid: 'new-uuid-no-bg' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns the status of background removal' do
      result = addons.remove_bg_status(request_id: request_id)

      expect(result).to be_success
      expect(result.value!['status']).to eq('done')
      expect(result.value!['result']['uuid']).to eq('new-uuid-no-bg')
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::AddOnsClient do
  let(:client) { described_class.new }
  let(:rest_api_root) { Uploadcare.configuration.rest_api_root }

  describe '#aws_rekognition_detect_labels' do
    let(:uuid) { '1bac376c-aa7e-4356-861b-dd2657b5bfd2' }
    let(:path) { '/addons/aws_rekognition_detect_labels/execute/' }
    let(:full_url) { "#{rest_api_root}#{path}" }
    let(:request_body) { { target: uuid } }

    subject { client.aws_rekognition_detect_labels(uuid) }

    context 'when the request is successful' do
      let(:response_body) { { 'request_id' => '8db3c8b4-2dea-4146-bcdb-63387e2b33c1' } }

      before do
        stub_request(:post, full_url)
          .with(body: request_body.to_json)
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it { is_expected.to eq(response_body) }
      it 'returns a valid request ID' do
        expect(subject['request_id']).to eq('8db3c8b4-2dea-4146-bcdb-63387e2b33c1')
      end
    end

    context 'when the request fails' do
      before do
        stub_request(:post, full_url)
          .with(body: request_body.to_json)
          .to_return(
            status: 400,
            body: { 'detail' => 'Bad Request' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an InvalidRequestError' do
        expect { subject }.to raise_error(Uploadcare::BadRequestError, "Bad Request")
      end
    end
  end

  describe '#aws_rekognition_detect_labels_status' do
    let(:request_id) { 'd1fb31c6-ed34-4e21-bdc3-4f1485f58e21' }
    let(:path) { '/addons/aws_rekognition_detect_labels/execute/status/' }
    let(:params) { { request_id: request_id } }
    let(:full_url) { "#{rest_api_root}#{path}" }

    subject { client.aws_rekognition_detect_labels_status(request_id) }

    context 'when the request is successful' do
      let(:response_body) { { 'status' => 'in_progress' } }

      before do
        stub_request(:get, full_url)
          .with(query: params)
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it { is_expected.to eq(response_body) }
      it 'returns the correct status' do
        expect(subject['status']).to eq('in_progress')
      end
    end

    context 'when the request fails' do
      before do
        stub_request(:get, full_url)
          .with(query: params)
          .to_return(
            status: 404,
            body: { 'detail' => 'Not Found' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises a NotFoundError' do
        expect { subject }.to raise_error(Uploadcare::NotFoundError)
      end
    end
  end

  describe '#aws_rekognition_detect_moderation_labels' do
    let(:uuid) { '1bac376c-aa7e-4356-861b-dd2657b5bfd2' }
    let(:response_body) do
      {
        'request_id' => '8db3c8b4-2dea-4146-bcdb-63387e2b33c1'
      }
    end

    before do
      stub_request(:post, 'https://api.uploadcare.com/addons/aws_rekognition_detect_moderation_labels/execute/')
        .with(body: { target: uuid })
        .to_return(
          status: 200,
          body: response_body.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns the request ID' do
      response = client.aws_rekognition_detect_moderation_labels(uuid)
      expect(response).to eq(response_body)
    end
  end
  describe '#aws_rekognition_detect_moderation_labels_status' do
    let(:request_id) { 'd1fb31c6-ed34-4e21-bdc3-4f1485f58e21' }
    let(:response_body) do
      {
        'status' => 'in_progress'
      }
    end

    before do
      stub_request(:get, 'https://api.uploadcare.com/addons/aws_rekognition_detect_moderation_labels/execute/status/')
        .with(query: { request_id: request_id })
        .to_return(
          status: 200,
          body: response_body.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns the status' do
      response = client.aws_rekognition_detect_moderation_labels_status(request_id)
      expect(response).to eq(response_body)
    end
  end

  describe '#uc_clamav_virus_scan' do
    let(:uuid) { '1bac376c-aa7e-4356-861b-dd2657b5bfd2' }
    let(:params) { { purge_infected: true } }
    let(:response_body) do
      {
        'request_id' => '8db3c8b4-2dea-4146-bcdb-63387e2b33c1'
      }
    end

    before do
      stub_request(:post, 'https://api.uploadcare.com/addons/uc_clamav_virus_scan/execute/')
        .with(body: { target: uuid, purge_infected: true }.to_json)
        .to_return(
          status: 200,
          body: response_body.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns the request ID' do
      response = client.uc_clamav_virus_scan(uuid, params)
      expect(response).to eq(response_body)
    end
  end

  describe '#uc_clamav_virus_scan_status' do
    let(:request_id) { '1bac376c-aa7e-4356-861b-dd2657b5bfd2' }
    let(:response_body) do
      {
        'status' => 'in_progress'
      }
    end

    before do
      stub_request(:get, 'https://api.uploadcare.com/addons/uc_clamav_virus_scan/execute/status/')
        .with(query: { request_id: request_id })
        .to_return(
          status: 200,
          body: response_body.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns the status' do
      response = client.uc_clamav_virus_scan_status(request_id)
      expect(response).to eq(response_body)
    end
  end

  describe '#remove_bg' do
    let(:uuid) { '21975c81-7f57-4c7a-aef9-acfe28779f78' }
    let(:params) { { crop: true, type_level: '2' } }
    let(:response_body) do
      {
        'request_id' => '8db3c8b4-2dea-4146-bcdb-63387e2b33c1'
      }
    end

    before do
      stub_request(:post, 'https://api.uploadcare.com/addons/remove_bg/execute/')
        .with(body: { target: uuid, params: params }.to_json)
        .to_return(
          status: 200,
          body: response_body.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns the request_id' do
      response = client.remove_bg(uuid, params)
      expect(response).to eq(response_body)
    end
  end

  describe '#remove_bg_status' do
    let(:request_id) { '1bac376c-aa7e-4356-861b-dd2657b5bfd2' }
    let(:response_body) do
      {
        'status' => 'done',
        'result' => { 'file_id' => '21975c81-7f57-4c7a-aef9-acfe28779f78' }
      }
    end

    before do
      stub_request(:get, 'https://api.uploadcare.com/addons/remove_bg/execute/status/')
        .with(query: { request_id: request_id })
        .to_return(
          status: 200,
          body: response_body.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns the status and result' do
      response = client.remove_bg_status(request_id)
      expect(response).to eq(response_body)
    end
  end
end

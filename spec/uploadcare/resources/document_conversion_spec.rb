# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Resources::DocumentConversion do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end
  let(:client) { Uploadcare::Client.new(config: config) }
  let(:rest) { instance_double(Uploadcare::Api::Rest) }
  let(:rest_doc_conversions) { double('document_conversions') }
  let(:api) { instance_double(Uploadcare::Client::Api, rest: rest) }

  let(:file_uuid) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }

  before do
    allow(client).to receive(:api).and_return(api)
    allow(rest).to receive(:document_conversions).and_return(rest_doc_conversions)
  end

  describe '.convert_document' do
    it 'converts a document to the specified format' do
      conversion_response = {
        'result' => [{ 'uuid' => 'converted-uuid', 'token' => 'job-token-123' }],
        'problems' => {}
      }

      allow(rest_doc_conversions).to receive(:convert)
        .with(
          paths: ["#{file_uuid}/document/-/format/pdf/"],
          options: {},
          request_options: {}
        )
        .and_return(Uploadcare::Result.success(conversion_response))

      result = described_class.convert_document(
        params: { uuid: file_uuid, format: 'pdf' },
        client: client
      )
      expect(result).to be_a(Hash)
      expect(result['result'].first['uuid']).to eq('converted-uuid')
    end

    it 'handles multiple UUIDs' do
      uuids = %w[uuid-1 uuid-2]
      conversion_response = {
        'result' => [
          { 'uuid' => 'converted-1' },
          { 'uuid' => 'converted-2' }
        ],
        'problems' => {}
      }

      allow(rest_doc_conversions).to receive(:convert)
        .with(
          paths: ['uuid-1/document/-/format/pdf/', 'uuid-2/document/-/format/pdf/'],
          options: {},
          request_options: {}
        )
        .and_return(Uploadcare::Result.success(conversion_response))

      result = described_class.convert_document(
        params: { uuid: uuids, format: 'pdf' },
        client: client
      )
      expect(result['result'].length).to eq(2)
    end

    it 'passes options through' do
      allow(rest_doc_conversions).to receive(:convert)
        .with(
          paths: ["#{file_uuid}/document/-/format/png/"],
          options: { store: true },
          request_options: {}
        )
        .and_return(Uploadcare::Result.success({ 'result' => [] }))

      described_class.convert_document(
        params: { uuid: file_uuid, format: 'png' },
        options: { store: true },
        client: client
      )
    end
  end

  describe '#info' do
    it 'fetches document format information' do
      conversion = described_class.new({}, client)
      info_response = {
        'format' => 'pdf',
        'error' => nil
      }

      allow(rest_doc_conversions).to receive(:info)
        .with(uuid: file_uuid, request_options: {})
        .and_return(Uploadcare::Result.success(info_response))

      result = conversion.info(uuid: file_uuid)
      expect(result).to eq(conversion)
      expect(conversion.format).to eq('pdf')
      expect(conversion.error).to be_nil
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

      allow(rest_doc_conversions).to receive(:status)
        .with(token: 'job-token-123', request_options: {})
        .and_return(Uploadcare::Result.success(status_response))

      result = conversion.fetch_status(token: 'job-token-123')
      expect(result).to eq(conversion)
      expect(conversion.status).to eq('finished')
      expect(conversion.result).to eq([{ 'uuid' => 'converted-uuid' }])
    end
  end

  describe 'attributes' do
    it 'exposes error, format, converted_groups, status, and result' do
      conversion = described_class.new(
        {
          'error' => nil,
          'format' => 'pdf',
          'status' => 'pending',
          'result' => [],
          'converted_groups' => []
        },
        client
      )
      expect(conversion.error).to be_nil
      expect(conversion.format).to eq('pdf')
      expect(conversion.status).to eq('pending')
      expect(conversion.result).to eq([])
      expect(conversion.converted_groups).to eq([])
    end
  end
end

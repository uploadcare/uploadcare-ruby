# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::DocumentConverterClient do
  let(:client) { described_class.new }
  let(:rest_api_root) { Uploadcare.configuration.rest_api_root }

  describe '#info' do
    let(:uuid) { SecureRandom.uuid }
    let(:path) { "/convert/document/#{uuid}/" }
    let(:full_url) { "#{rest_api_root}#{path}" }

    subject { client.info(uuid) }

    context 'when the request is successful' do
      let(:response_body) do
        {
          'format' => { 'name' => 'pdf', 'conversion_formats' => [{ 'name' => 'txt' }] },
          'converted_groups' => { 'pdf' => 'group_uuid~1' },
          'error' => nil
        }
      end

      before do
        stub_request(:get, full_url)
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it { is_expected.to eq(response_body) }
    end

    context 'when the request returns an error' do
      before do
        stub_request(:get, full_url)
          .to_return(status: 404, body: { 'detail' => 'Not found' }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises a NotFoundError' do
        expect { client.info(uuid) }.to raise_error(Uploadcare::NotFoundError)
      end
    end
  end

  describe '#convert_document' do
    let(:path) { '/convert/document/' }
    let(:full_url) { "#{rest_api_root}#{path}" }
    let(:document_params) { { uuid: 'doc_uuid', format: :pdf } }
    let(:options) { { store: true, save_in_group: false } }
    let(:paths) { ['doc_uuid/document/-/format/pdf/'] }

    subject { client.convert_document(paths, options) }

    context 'when the request is successful' do
      let(:response_body) do
        {
          'problems' => {},
          'result' => [
            {
              'original_source' => 'doc_uuid/document/-/format/pdf/',
              'token' => 445_630_631,
              'uuid' => 'd52d7136-a2e5-4338-9f45-affbf83b857d'
            }
          ]
        }
      end

      before do
        stub_request(:post, full_url)
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it { is_expected.to eq(response_body) }
    end
  end

  describe '#status' do
    let(:token) { 123_456_789 }
    let(:path) { "/convert/document/status/#{token}/" }
    let(:full_url) { "#{rest_api_root}#{path}" }

    subject { client.status(token) }

    context 'when the request is successful' do
      let(:response_body) do
        {
          'status' => 'processing',
          'error' => nil,
          'result' => { 'uuid' => 'd52d7136-a2e5-4338-9f45-affbf83b857d' }
        }
      end

      before do
        stub_request(:get, full_url)
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it { is_expected.to eq(response_body) }
    end
  end
end

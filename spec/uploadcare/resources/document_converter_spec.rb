# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::DocumentConverter do
  let(:uuid) { SecureRandom.uuid }
  let(:token) { '32921143' }
  subject(:document_converter) { described_class.new }

  describe '#info' do
    let(:response_body) do
      {
        'format' => { 'name' => 'pdf', 'conversion_formats' => [{ 'name' => 'txt' }] },
        'converted_groups' => { 'pdf' => 'group_uuid~1' },
        'error' => nil
      }
    end

    subject { document_converter.info(uuid) }

    before do
      allow_any_instance_of(Uploadcare::DocumentConverterClient).to receive(:info).with(uuid).and_return(response_body)
    end

    it 'assigns attributes correctly' do
      expect(subject.format['name']).to eq('pdf')
      expect(subject.converted_groups['pdf']).to eq('group_uuid~1')
    end
  end

  describe '.convert_document' do
    let(:document_params) { { uuid: 'doc_uuid', format: :pdf } }
    let(:options) { { store: true, save_in_group: false } }
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

    subject { described_class.convert_document(document_params, options) }

    before do
      allow_any_instance_of(Uploadcare::DocumentConverterClient).to receive(:convert_document)
        .with(['doc_uuid/document/-/format/pdf/'], options).and_return(response_body)
    end

    it { is_expected.to eq(response_body) }
  end

  describe '#status' do
    let(:response_body) do
      {
        'status' => 'processing',
        'error' => nil,
        'result' => { 'uuid' => 'd52d7136-a2e5-4338-9f45-affbf83b857d' }
      }
    end

    subject { document_converter.fetch_status(token) }

    before do
      allow_any_instance_of(Uploadcare::DocumentConverterClient).to receive(:status).with(token).and_return(response_body)
    end

    it { is_expected.to be_a(Uploadcare::DocumentConverter) }

    it 'assigns attributecorrectly' do
      expect(subject.status).to eq(response_body['status'])
      expect(subject.result['uuid']).to eq(response_body['result']['uuid'])
    end
  end
end

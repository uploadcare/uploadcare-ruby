# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Collections::BatchResult do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end
  let(:client) { Uploadcare::Client.new(config: config) }
  let(:file_uuid) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }

  let(:file_data) do
    {
      'uuid' => file_uuid,
      'original_filename' => 'photo.jpg',
      'size' => 12_345,
      'is_ready' => true
    }
  end

  describe '#initialize' do
    it 'creates File objects from result data' do
      batch = described_class.new(
        status: 'ok',
        result: [file_data],
        problems: {},
        client: client
      )

      expect(batch.status).to eq('ok')
      expect(batch.result).to be_an(Array)
      expect(batch.result.length).to eq(1)
      expect(batch.result.first).to be_a(Uploadcare::Resources::File)
      expect(batch.result.first.uuid).to eq(file_uuid)
      expect(batch.result.first.original_filename).to eq('photo.jpg')
      expect(batch.problems).to eq({})
    end

    it 'handles nil result gracefully' do
      batch = described_class.new(
        status: 'ok',
        result: nil,
        problems: {},
        client: client
      )

      expect(batch.result).to eq([])
    end

    it 'handles nil problems' do
      batch = described_class.new(
        status: 'ok',
        result: [],
        problems: nil,
        client: client
      )

      expect(batch.problems).to eq({})
    end

    it 'stores problems hash' do
      problems = {
        'bad-uuid-1' => 'File not found.',
        'bad-uuid-2' => 'File is already stored.'
      }

      batch = described_class.new(
        status: 'ok',
        result: [file_data],
        problems: problems,
        client: client
      )

      expect(batch.problems).to eq(problems)
      expect(batch.problems['bad-uuid-1']).to eq('File not found.')
    end
  end

  describe '#status' do
    it 'returns the status' do
      batch = described_class.new(status: 200, result: [], problems: {}, client: client)
      expect(batch.status).to eq(200)
    end

    it 'can be nil' do
      batch = described_class.new(status: nil, result: [], problems: {}, client: client)
      expect(batch.status).to be_nil
    end
  end

  describe '#result' do
    it 'returns File objects with proper client context' do
      batch = described_class.new(
        status: 'ok',
        result: [file_data, file_data.merge('uuid' => 'second-uuid')],
        problems: {},
        client: client
      )

      expect(batch.result.length).to eq(2)
      batch.result.each do |file|
        expect(file).to be_a(Uploadcare::Resources::File)
        expect(file.client).to eq(client)
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Resources::FileTags do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end
  let(:client) { Uploadcare::Client.new(config: config) }
  let(:rest) { instance_double(Uploadcare::Api::Rest) }
  let(:rest_file_tags) { instance_double(Uploadcare::Api::Rest::FileTags) }
  let(:api) { instance_double(Uploadcare::Client::Api, rest: rest) }
  let(:file_uuid) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }

  before do
    allow(client).to receive(:api).and_return(api)
    allow(rest).to receive(:file_tags).and_return(rest_file_tags)
  end

  describe '.list' do
    it 'returns the current ordered tag list' do
      allow(rest_file_tags).to receive(:list)
        .with(uuid: file_uuid, request_options: {})
        .and_return(Uploadcare::Result.success({ 'tags' => %w[cat animal] }))

      expect(described_class.list(uuid: file_uuid, client: client)).to eq(%w[cat animal])
    end
  end

  describe '.replace' do
    it 'normalizes tags and returns the tag change resource' do
      allow(rest_file_tags).to receive(:replace)
        .with(uuid: file_uuid, tags: %w[cat animal], request_options: {})
        .and_return(
          Uploadcare::Result.success(
            { 'tags' => %w[cat animal], 'added' => %w[animal cat], 'deleted' => ['old'] }
          )
        )

      result = described_class.replace(uuid: file_uuid, tags: [' Cat ', 'ANIMAL', 'cat'], client: client)

      expect(result.tags).to eq(%w[cat animal])
      expect(result.added).to eq(%w[animal cat])
      expect(result.deleted).to eq(['old'])
      expect(result.uuid).to eq(file_uuid)
    end

    it 'sends an empty array to clear all tags' do
      allow(rest_file_tags).to receive(:replace)
        .with(uuid: file_uuid, tags: [], request_options: {})
        .and_return(Uploadcare::Result.success({ 'tags' => [], 'added' => [], 'deleted' => ['old'] }))

      result = described_class.replace(uuid: file_uuid, tags: [], client: client)

      expect(result.tags).to eq([])
      expect(result.deleted).to eq(['old'])
    end

    it 'rejects nil instead of clearing tags' do
      expect do
        described_class.replace(uuid: file_uuid, tags: nil, client: client)
      end.to raise_error(ArgumentError, /array of strings/)
    end
  end

  describe '.update' do
    it 'normalizes additions and deletions and returns actual changes' do
      allow(rest_file_tags).to receive(:update)
        .with(uuid: file_uuid, add: %w[summer featured], delete: ['draft'], request_options: {})
        .and_return(
          Uploadcare::Result.success(
            { 'tags' => %w[summer featured], 'added' => %w[summer featured], 'deleted' => ['draft'] }
          )
        )

      result = described_class.update(
        uuid: file_uuid,
        add: [' Summer ', 'FEATURED', 'summer'],
        delete: ['DRAFT'],
        client: client
      )

      expect(result.tags).to eq(%w[summer featured])
      expect(result.added).to eq(%w[summer featured])
      expect(result.deleted).to eq(['draft'])
    end
  end

  describe 'instance operations' do
    subject(:resource) { described_class.new({ uuid: file_uuid }, client) }

    it 'refreshes its tag state with #list' do
      allow(rest_file_tags).to receive(:list)
        .and_return(Uploadcare::Result.success({ 'tags' => ['current'] }))

      expect(resource.list).to equal(resource)
      expect(resource.tags).to eq(['current'])
    end
  end
end

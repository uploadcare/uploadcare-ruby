# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare do
  describe '.configure' do
    it 'yields configuration block' do
      expect { |b| described_class.configure(&b) }.to yield_with_args(described_class.configuration)
    end

    it 'allows setting configuration values' do
      described_class.configure do |config|
        config.public_key = 'test_key'
        config.upload_timeout = 120
      end

      expect(described_class.configuration.public_key).to eq('test_key')
      expect(described_class.configuration.upload_timeout).to eq(120)
    end

    it 'resets the memoized client' do
      client1 = described_class.client
      described_class.configure { |c| c.public_key = 'new_key' }
      client2 = described_class.client
      expect(client1).not_to equal(client2)
    end

    it 'resets the memoized client even when the block raises' do
      client1 = described_class.client

      expect do
        described_class.configure do |config|
          config.public_key = 'broken'
          raise 'boom'
        end
      end.to raise_error(RuntimeError, 'boom')

      client2 = described_class.client
      expect(client1).not_to equal(client2)
      expect(client2.config.public_key).to eq('broken')
    end
  end

  describe '.configuration' do
    it 'returns a Configuration instance' do
      expect(described_class.configuration).to be_a(Uploadcare::Configuration)
    end

    it 'memoizes the configuration' do
      config1 = described_class.configuration
      config2 = described_class.configuration
      expect(config1).to be(config2)
    end
  end

  describe '.client' do
    it 'returns a Client instance' do
      expect(described_class.client).to be_a(Uploadcare::Client)
    end

    it 'memoizes the default client' do
      client1 = described_class.client
      client2 = described_class.client
      expect(client1).to equal(client2)
    end

    it 'creates new client with custom config' do
      custom = Uploadcare::Configuration.new(public_key: 'custom')
      c = described_class.client(config: custom)
      expect(c.config.public_key).to eq('custom')
    end

    it 'creates new client with option overrides' do
      c = described_class.client(public_key: 'override')
      expect(c.config.public_key).to eq('override')
    end
  end

  describe '.files' do
    it 'returns a FilesAccessor' do
      expect(described_class.files).to be_a(Uploadcare::Client::FilesAccessor)
    end
  end

  describe '.groups' do
    it 'returns a GroupsAccessor' do
      expect(described_class.groups).to be_a(Uploadcare::Client::GroupsAccessor)
    end
  end

  describe '.uploads' do
    it 'returns an UploadRouter' do
      expect(described_class.uploads).to be_a(Uploadcare::Operations::UploadRouter)
    end
  end

  describe '.project' do
    it 'returns a ProjectAccessor' do
      expect(described_class.project).to be_a(Uploadcare::Client::ProjectAccessor)
    end
  end

  describe '.eager_load!' do
    it 'does not raise errors' do
      expect { Uploadcare.eager_load! }.not_to raise_error
    end
  end

  describe 'top-level constants' do
    it 'aliases Resources::File as File' do
      expect(Uploadcare::File).to eq(Uploadcare::Resources::File)
    end

    it 'aliases Resources::Group as Group' do
      expect(Uploadcare::Group).to eq(Uploadcare::Resources::Group)
    end

    it 'aliases Resources::Project as Project' do
      expect(Uploadcare::Project).to eq(Uploadcare::Resources::Project)
    end

    it 'aliases Resources::Webhook as Webhook' do
      expect(Uploadcare::Webhook).to eq(Uploadcare::Resources::Webhook)
    end

    it 'aliases Resources::AddonExecution as AddonExecution' do
      expect(Uploadcare::AddonExecution).to eq(Uploadcare::Resources::AddonExecution)
    end

    it 'aliases Resources::DocumentConversion as DocumentConversion' do
      expect(Uploadcare::DocumentConversion).to eq(Uploadcare::Resources::DocumentConversion)
    end

    it 'aliases Resources::VideoConversion as VideoConversion' do
      expect(Uploadcare::VideoConversion).to eq(Uploadcare::Resources::VideoConversion)
    end
  end
end

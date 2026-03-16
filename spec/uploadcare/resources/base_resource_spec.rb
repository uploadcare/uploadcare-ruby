# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Resources::BaseResource do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end
  let(:client) { Uploadcare::Client.new(config: config) }

  describe '#initialize' do
    it 'accepts attributes and a client' do
      resource = described_class.new({}, client)
      expect(resource.client).to eq(client)
      expect(resource.config).to eq(client.config)
    end

    it 'raises when no client or config is given' do
      expect {
        described_class.new({})
      }.to raise_error(ArgumentError, /client or config is required/)
    end

    it 'resolves a Configuration into a client' do
      resource = described_class.new({}, config)
      expect(resource.client).to be_a(Uploadcare::Client)
      expect(resource.config.public_key).to eq('demopublickey')
    end
  end

  describe '.resolve_client' do
    it 'returns the explicit client when provided' do
      result = described_class.resolve_client(client: client)
      expect(result).to eq(client)
    end

    it 'wraps a Configuration in a client' do
      result = described_class.resolve_client(config)
      expect(result).to be_a(Uploadcare::Client)
      expect(result.config.public_key).to eq('demopublickey')
    end

    it 'wraps a Client passed as first argument' do
      result = described_class.resolve_client(client)
      expect(result).to eq(client)
    end

    it 'raises for nil' do
      expect {
        described_class.resolve_client(nil)
      }.to raise_error(ArgumentError, /client or config is required/)
    end
  end

  describe '#assign_attributes' do
    it 'sets attributes via setter methods' do
      klass = Class.new(described_class) do
        attr_accessor :name, :value
      end

      resource = klass.new({ 'name' => 'test', 'value' => 42 }, client)
      expect(resource.name).to eq('test')
      expect(resource.value).to eq(42)
    end

    it 'ignores attributes without setter methods' do
      expect {
        described_class.new({ 'nonexistent_attr' => 'ignored' }, client)
      }.not_to raise_error
    end
  end
end

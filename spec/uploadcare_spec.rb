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

  describe '.eager_load!' do
    it 'eager loads all modules' do
      expect { described_class.eager_load! }.not_to raise_error
    end
  end
end

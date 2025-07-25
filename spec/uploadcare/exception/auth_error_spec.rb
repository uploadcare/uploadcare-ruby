# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Exception::AuthError do
  describe '#initialize' do
    it 'inherits from StandardError' do
      expect(described_class.superclass).to eq(StandardError)
    end

    it 'can be instantiated with a message' do
      error = described_class.new('Invalid authentication')
      expect(error.message).to eq('Invalid authentication')
    end

    it 'can be instantiated without a message' do
      error = described_class.new
      expect(error.message).to eq('Uploadcare::Exception::AuthError')
    end
  end

  describe 'raising the error' do
    it 'can be raised as an exception' do
      expect { raise described_class }.to raise_error(described_class)
    end

    it 'can be raised with a custom message' do
      expect { raise described_class, 'API key missing' }
        .to raise_error(described_class, 'API key missing')
    end
  end

  describe 'rescue behavior' do
    it 'can be rescued as AuthError' do
      result = begin
        raise described_class, 'Auth failed'
      rescue described_class => e
        e.message
      end
      expect(result).to eq('Auth failed')
    end

    it 'can be rescued as StandardError' do
      result = begin
        raise described_class, 'Auth failed'
      rescue StandardError => e
        e.message
      end
      expect(result).to eq('Auth failed')
    end
  end
end
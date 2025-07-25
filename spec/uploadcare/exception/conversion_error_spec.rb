# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Exception::ConversionError do
  describe '#initialize' do
    it 'inherits from StandardError' do
      expect(described_class.superclass).to eq(StandardError)
    end

    it 'can be instantiated with a message' do
      error = described_class.new('Conversion failed')
      expect(error.message).to eq('Conversion failed')
    end

    it 'can be instantiated without a message' do
      error = described_class.new
      expect(error.message).to eq('Uploadcare::Exception::ConversionError')
    end
  end

  describe 'raising the error' do
    it 'can be raised as an exception' do
      expect { raise described_class }.to raise_error(described_class)
    end

    it 'can be raised with a custom message' do
      expect { raise described_class, 'Invalid conversion format' }
        .to raise_error(described_class, 'Invalid conversion format')
    end
  end

  describe 'rescue behavior' do
    it 'can be rescued as ConversionError' do
      result = begin
        raise described_class, 'Conversion error occurred'
      rescue described_class => e
        e.message
      end
      expect(result).to eq('Conversion error occurred')
    end

    it 'can be rescued as StandardError' do
      result = begin
        raise described_class, 'Conversion error occurred'
      rescue StandardError => e
        e.message
      end
      expect(result).to eq('Conversion error occurred')
    end
  end

  describe 'use cases' do
    context 'when API conversion response is invalid' do
      it 'provides meaningful error messages' do
        error = described_class.new('Unsupported file format for conversion')
        expect(error.message).to eq('Unsupported file format for conversion')
      end
    end

    context 'when conversion parameters are invalid' do
      it 'can indicate parameter issues' do
        error = described_class.new('Invalid conversion parameters: width must be positive')
        expect(error.message).to eq('Invalid conversion parameters: width must be positive')
      end
    end
  end
end

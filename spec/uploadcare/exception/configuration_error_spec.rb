# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Exception::ConfigurationError do
  describe 'inheritance' do
    it 'inherits from StandardError' do
      expect(described_class).to be < StandardError
    end
  end

  describe 'initialization' do
    it 'can be initialized without arguments' do
      expect { described_class.new }.not_to raise_error
    end

    it 'can be initialized with a message' do
      error = described_class.new('Invalid configuration')
      expect(error.message).to eq('Invalid configuration')
    end

    it 'accepts various message types' do
      error_with_string = described_class.new('String message')
      expect(error_with_string.message).to eq('String message')

      error_with_symbol = described_class.new(:symbol_message)
      expect(error_with_symbol.message).to eq('symbol_message')
    end
  end

  describe 'raising and catching' do
    it 'can be raised and caught' do
      expect do
        raise described_class, 'Configuration error'
      end.to raise_error(described_class, 'Configuration error')
    end

    it 'can be caught as StandardError' do
      expect do
        raise described_class, 'Configuration error'
      end.to raise_error(StandardError)
    end

    it 'can be caught as Uploadcare::Exception::ConfigurationError' do
      expect do
        raise described_class, 'Configuration error'
      end.to raise_error(Uploadcare::Exception::ConfigurationError)
    end
  end

  describe 'configuration error scenarios' do
    it 'handles missing public key scenario' do
      expect do
        raise described_class, 'Public key is required but not provided'
      end.to raise_error(described_class, 'Public key is required but not provided')
    end

    it 'handles invalid API endpoint scenario' do
      expect do
        raise described_class, 'Invalid API endpoint URL configured'
      end.to raise_error(described_class, 'Invalid API endpoint URL configured')
    end

    it 'handles invalid timeout values scenario' do
      expect do
        raise described_class, 'Timeout value must be a positive number'
      end.to raise_error(described_class, 'Timeout value must be a positive number')
    end

    it 'handles invalid retry configuration scenario' do
      expect do
        raise described_class, 'Max retries must be between 0 and 10'
      end.to raise_error(described_class, 'Max retries must be between 0 and 10')
    end

    it 'handles invalid CDN configuration scenario' do
      expect do
        raise described_class, 'CDN URL format is invalid'
      end.to raise_error(described_class, 'CDN URL format is invalid')
    end
  end

  describe 'validation error scenarios' do
    it 'handles multiple validation errors' do
      errors = [
        'Public key format is invalid',
        'Secret key is too short',
        'API endpoint must use HTTPS'
      ]
      message = "Configuration validation failed:\n#{errors.join("\n")}"

      expect do
        raise described_class, message
      end.to raise_error(described_class, message)
    end

    it 'handles nested configuration errors' do
      expect do
        raise described_class, 'Upload.store setting must be "auto", true, or false'
      end.to raise_error(described_class, 'Upload.store setting must be "auto", true, or false')
    end
  end

  describe 'message formatting' do
    it 'preserves detailed error messages' do
      detailed_message = "Configuration Error in uploadcare.rb:15\n" \
                         "Invalid public key format: 'invalid_key'\n" \
                         'Expected format: pub_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
      error = described_class.new(detailed_message)
      expect(error.message).to eq(detailed_message)
    end

    it 'handles structured error data' do
      structured_message = {
        field: 'public_key',
        value: 'invalid',
        expected: 'pub_* format',
        line: 42
      }.to_s

      error = described_class.new(structured_message)
      expect(error.message).to include('public_key')
      expect(error.message).to include('invalid')
    end
  end

  describe 'error context' do
    it 'provides context about configuration source' do
      expect do
        raise described_class, 'Environment variable UPLOADCARE_PUBLIC_KEY is invalid'
      end.to raise_error(described_class, /Environment variable.*invalid/)
    end

    it 'provides context about configuration file' do
      expect do
        raise described_class, 'Configuration file config/uploadcare.yml contains invalid settings'
      end.to raise_error(described_class, /Configuration file.*invalid/)
    end
  end

  describe 'backtrace handling' do
    it 'preserves backtrace information' do
      raise described_class, 'Config error'
    rescue described_class => e
      expect(e.backtrace).to be_an(Array)
      expect(e.backtrace.first).to include(__FILE__)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Exception::AuthError do
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
      error = described_class.new('Invalid API key')
      expect(error.message).to eq('Invalid API key')
    end

    it 'can be initialized with a message and cause' do
      StandardError.new('Original error')
      error = described_class.new('Invalid API key')
      error = error.exception('Invalid API key')
      expect(error.message).to eq('Invalid API key')
    end
  end

  describe 'raising and catching' do
    it 'can be raised and caught' do
      expect do
        raise described_class, 'Authentication failed'
      end.to raise_error(described_class, 'Authentication failed')
    end

    it 'can be caught as StandardError' do
      expect do
        raise described_class, 'Authentication failed'
      end.to raise_error(StandardError)
    end

    it 'can be caught as Uploadcare::Exception::AuthError' do
      expect do
        raise described_class, 'Authentication failed'
      end.to raise_error(Uploadcare::Exception::AuthError)
    end
  end

  describe 'error handling scenarios' do
    it 'handles invalid API key scenario' do
      expect do
        raise described_class, 'Invalid API key provided'
      end.to raise_error(described_class, 'Invalid API key provided')
    end

    it 'handles missing authentication scenario' do
      expect do
        raise described_class, 'Authentication credentials missing'
      end.to raise_error(described_class, 'Authentication credentials missing')
    end

    it 'handles expired token scenario' do
      expect do
        raise described_class, 'Authentication token has expired'
      end.to raise_error(described_class, 'Authentication token has expired')
    end

    it 'handles insufficient permissions scenario' do
      expect do
        raise described_class, 'Insufficient permissions for this operation'
      end.to raise_error(described_class, 'Insufficient permissions for this operation')
    end
  end

  describe 'message formatting' do
    it 'preserves custom message formatting' do
      message = "Auth Error: Invalid key 'pub_123' - please check your configuration"
      error = described_class.new(message)
      expect(error.message).to eq(message)
    end

    it 'handles multi-line error messages' do
      message = "Authentication failed:\n- Invalid public key\n- Secret key not provided"
      error = described_class.new(message)
      expect(error.message).to include('Authentication failed')
      expect(error.message).to include('Invalid public key')
      expect(error.message).to include('Secret key not provided')
    end
  end

  describe 'backtrace handling' do
    it 'preserves backtrace information' do
      raise described_class, 'Auth failed'
    rescue described_class => e
      expect(e.backtrace).to be_an(Array)
      expect(e.backtrace.first).to include(__FILE__)
    end
  end
end

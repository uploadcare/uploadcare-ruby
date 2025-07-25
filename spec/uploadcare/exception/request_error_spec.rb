# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Exception::RequestError do
  describe '#initialize' do
    it 'inherits from StandardError' do
      expect(described_class.superclass).to eq(StandardError)
    end

    it 'can be instantiated with a message' do
      error = described_class.new('Bad request')
      expect(error.message).to eq('Bad request')
    end

    it 'can be instantiated without a message' do
      error = described_class.new
      expect(error.message).to eq('Uploadcare::Exception::RequestError')
    end
  end

  describe 'raising the error' do
    it 'can be raised as an exception' do
      expect { raise described_class }.to raise_error(described_class)
    end

    it 'can be raised with a custom message' do
      expect { raise described_class, '404 Not Found' }
        .to raise_error(described_class, '404 Not Found')
    end
  end

  describe 'rescue behavior' do
    it 'can be rescued as RequestError' do
      result = begin
        raise described_class, 'Request failed'
      rescue described_class => e
        e.message
      end
      expect(result).to eq('Request failed')
    end

    it 'can be rescued as StandardError' do
      result = begin
        raise described_class, 'Request failed'
      rescue StandardError => e
        e.message
      end
      expect(result).to eq('Request failed')
    end
  end

  describe 'use cases' do
    context 'when API returns an error' do
      it 'can represent various HTTP errors' do
        errors = {
          '400' => 'Bad Request',
          '401' => 'Unauthorized',
          '403' => 'Forbidden',
          '404' => 'Not Found',
          '500' => 'Internal Server Error'
        }

        errors.each do |code, message|
          error = described_class.new("#{code}: #{message}")
          expect(error.message).to eq("#{code}: #{message}")
        end
      end
    end

    context 'when request validation fails' do
      it 'can indicate validation errors' do
        error = described_class.new('Invalid request parameters')
        expect(error.message).to eq('Invalid request parameters')
      end
    end

    context 'when API response is malformed' do
      it 'can indicate parsing errors' do
        error = described_class.new('Invalid JSON response from API')
        expect(error.message).to eq('Invalid JSON response from API')
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Exception::ConversionError do
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
      error = described_class.new('Conversion failed')
      expect(error.message).to eq('Conversion failed')
    end

    it 'accepts detailed conversion error messages' do
      message = 'Document conversion failed: unsupported format'
      error = described_class.new(message)
      expect(error.message).to eq(message)
    end
  end

  describe 'raising and catching' do
    it 'can be raised and caught' do
      expect do
        raise described_class, 'Conversion error'
      end.to raise_error(described_class, 'Conversion error')
    end

    it 'can be caught as StandardError' do
      expect do
        raise described_class, 'Conversion error'
      end.to raise_error(StandardError)
    end

    it 'can be caught as Uploadcare::Exception::ConversionError' do
      expect do
        raise described_class, 'Conversion error'
      end.to raise_error(Uploadcare::Exception::ConversionError)
    end
  end

  describe 'document conversion error scenarios' do
    it 'handles unsupported format errors' do
      expect do
        raise described_class, 'Document format .xyz is not supported for conversion'
      end.to raise_error(described_class, 'Document format .xyz is not supported for conversion')
    end

    it 'handles conversion timeout errors' do
      expect do
        raise described_class, 'Document conversion timed out after 300 seconds'
      end.to raise_error(described_class, 'Document conversion timed out after 300 seconds')
    end

    it 'handles corrupted file errors' do
      expect do
        raise described_class, 'Document appears to be corrupted and cannot be converted'
      end.to raise_error(described_class, 'Document appears to be corrupted and cannot be converted')
    end

    it 'handles password protected document errors' do
      expect do
        raise described_class, 'Cannot convert password-protected document without password'
      end.to raise_error(described_class, 'Cannot convert password-protected document without password')
    end
  end

  describe 'video conversion error scenarios' do
    it 'handles unsupported video format errors' do
      expect do
        raise described_class, 'Video codec H.265 is not supported for conversion'
      end.to raise_error(described_class, 'Video codec H.265 is not supported for conversion')
    end

    it 'handles video processing errors' do
      expect do
        raise described_class, 'Video conversion failed: invalid resolution specified'
      end.to raise_error(described_class, 'Video conversion failed: invalid resolution specified')
    end

    it 'handles video size limit errors' do
      expect do
        raise described_class, 'Video file size exceeds maximum limit for conversion (2GB)'
      end.to raise_error(described_class, 'Video file size exceeds maximum limit for conversion (2GB)')
    end

    it 'handles video duration limit errors' do
      expect do
        raise described_class, 'Video duration exceeds maximum limit (2 hours)'
      end.to raise_error(described_class, 'Video duration exceeds maximum limit (2 hours)')
    end
  end

  describe 'image conversion error scenarios' do
    it 'handles unsupported image format errors' do
      expect do
        raise described_class, 'Image format .bmp is not supported for this conversion'
      end.to raise_error(described_class, 'Image format .bmp is not supported for this conversion')
    end

    it 'handles image size errors' do
      expect do
        raise described_class, 'Image dimensions 50000x50000 exceed maximum supported size'
      end.to raise_error(described_class, 'Image dimensions 50000x50000 exceed maximum supported size')
    end

    it 'handles invalid transformation errors' do
      expect do
        raise described_class, 'Invalid image transformation parameters specified'
      end.to raise_error(described_class, 'Invalid image transformation parameters specified')
    end
  end

  describe 'conversion job error scenarios' do
    it 'handles job not found errors' do
      expect do
        raise described_class, 'Conversion job with ID abc123 not found'
      end.to raise_error(described_class, 'Conversion job with ID abc123 not found')
    end

    it 'handles job failure errors' do
      expect do
        raise described_class, 'Conversion job failed with status: error'
      end.to raise_error(described_class, 'Conversion job failed with status: error')
    end

    it 'handles job cancellation errors' do
      expect do
        raise described_class, 'Conversion job was cancelled before completion'
      end.to raise_error(described_class, 'Conversion job was cancelled before completion')
    end
  end

  describe 'API-specific conversion errors' do
    it 'handles API quota exceeded errors' do
      expect do
        raise described_class, 'Monthly conversion quota exceeded. Upgrade plan to continue.'
      end.to raise_error(described_class, 'Monthly conversion quota exceeded. Upgrade plan to continue.')
    end

    it 'handles feature not available errors' do
      expect do
        raise described_class, 'Advanced conversion features not available on current plan'
      end.to raise_error(described_class, 'Advanced conversion features not available on current plan')
    end

    it 'handles service unavailable errors' do
      expect do
        raise described_class, 'Conversion service temporarily unavailable. Please try again later.'
      end.to raise_error(described_class, 'Conversion service temporarily unavailable. Please try again later.')
    end
  end

  describe 'message formatting' do
    it 'preserves structured error messages' do
      message = "Conversion Error:\n  " \
                "Job ID: job_123\n  " \
                "File: document.pdf\n  " \
                'Error: Unsupported encryption method'
      error = described_class.new(message)
      expect(error.message).to eq(message)
    end

    it 'handles JSON-formatted error messages' do
      json_message = '{"error":"conversion_failed","details":"Invalid format","job_id":"123"}'
      error = described_class.new(json_message)
      expect(error.message).to eq(json_message)
    end
  end

  describe 'backtrace handling' do
    it 'preserves backtrace information' do
      raise described_class, 'Conversion failed'
    rescue described_class => e
      expect(e.backtrace).to be_an(Array)
      expect(e.backtrace.first).to include(__FILE__)
    end
  end
end

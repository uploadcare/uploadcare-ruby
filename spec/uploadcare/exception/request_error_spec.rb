# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Exception::RequestError do
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
      error = described_class.new('Request failed')
      expect(error.message).to eq('Request failed')
    end

    it 'accepts HTTP error messages' do
      message = 'HTTP 404: File not found'
      error = described_class.new(message)
      expect(error.message).to eq(message)
    end
  end

  describe 'raising and catching' do
    it 'can be raised and caught' do
      expect do
        raise described_class, 'Request error'
      end.to raise_error(described_class, 'Request error')
    end

    it 'can be caught as StandardError' do
      expect do
        raise described_class, 'Request error'
      end.to raise_error(StandardError)
    end

    it 'can be caught as Uploadcare::Exception::RequestError' do
      expect do
        raise described_class, 'Request error'
      end.to raise_error(Uploadcare::Exception::RequestError)
    end
  end

  describe 'HTTP error scenarios' do
    it 'handles 400 Bad Request errors' do
      expect do
        raise described_class, 'HTTP 400: Bad Request - Invalid parameters'
      end.to raise_error(described_class, 'HTTP 400: Bad Request - Invalid parameters')
    end

    it 'handles 401 Unauthorized errors' do
      expect do
        raise described_class, 'HTTP 401: Unauthorized - Invalid API key'
      end.to raise_error(described_class, 'HTTP 401: Unauthorized - Invalid API key')
    end

    it 'handles 403 Forbidden errors' do
      expect do
        raise described_class, 'HTTP 403: Forbidden - Access denied'
      end.to raise_error(described_class, 'HTTP 403: Forbidden - Access denied')
    end

    it 'handles 404 Not Found errors' do
      expect do
        raise described_class, 'HTTP 404: Not Found - File does not exist'
      end.to raise_error(described_class, 'HTTP 404: Not Found - File does not exist')
    end

    it 'handles 429 Too Many Requests errors' do
      expect do
        raise described_class, 'HTTP 429: Too Many Requests - Rate limit exceeded'
      end.to raise_error(described_class, 'HTTP 429: Too Many Requests - Rate limit exceeded')
    end

    it 'handles 500 Internal Server Error errors' do
      expect do
        raise described_class, 'HTTP 500: Internal Server Error - Server malfunction'
      end.to raise_error(described_class, 'HTTP 500: Internal Server Error - Server malfunction')
    end

    it 'handles 502 Bad Gateway errors' do
      expect do
        raise described_class, 'HTTP 502: Bad Gateway - Upstream server error'
      end.to raise_error(described_class, 'HTTP 502: Bad Gateway - Upstream server error')
    end

    it 'handles 503 Service Unavailable errors' do
      expect do
        raise described_class, 'HTTP 503: Service Unavailable - Server maintenance'
      end.to raise_error(described_class, 'HTTP 503: Service Unavailable - Server maintenance')
    end
  end

  describe 'API-specific error scenarios' do
    it 'handles invalid file format errors' do
      expect do
        raise described_class, 'File format not supported: application/unknown'
      end.to raise_error(described_class, 'File format not supported: application/unknown')
    end

    it 'handles file size limit errors' do
      expect do
        raise described_class, 'File size exceeds maximum limit: 100MB'
      end.to raise_error(described_class, 'File size exceeds maximum limit: 100MB')
    end

    it 'handles quota exceeded errors' do
      expect do
        raise described_class, 'Monthly upload quota exceeded: 1GB limit reached'
      end.to raise_error(described_class, 'Monthly upload quota exceeded: 1GB limit reached')
    end

    it 'handles invalid file UUID errors' do
      expect do
        raise described_class, 'Invalid file UUID format: abc-123-invalid'
      end.to raise_error(described_class, 'Invalid file UUID format: abc-123-invalid')
    end

    it 'handles expired file URL errors' do
      expect do
        raise described_class, 'File URL has expired and is no longer accessible'
      end.to raise_error(described_class, 'File URL has expired and is no longer accessible')
    end
  end

  describe 'network error scenarios' do
    it 'handles connection timeout errors' do
      expect do
        raise described_class, 'Request timeout: Connection timed out after 30 seconds'
      end.to raise_error(described_class, 'Request timeout: Connection timed out after 30 seconds')
    end

    it 'handles connection refused errors' do
      expect do
        raise described_class, 'Connection refused: Unable to connect to api.uploadcare.com'
      end.to raise_error(described_class, 'Connection refused: Unable to connect to api.uploadcare.com')
    end

    it 'handles DNS resolution errors' do
      expect do
        raise described_class, 'DNS resolution failed: Cannot resolve hostname'
      end.to raise_error(described_class, 'DNS resolution failed: Cannot resolve hostname')
    end

    it 'handles SSL certificate errors' do
      expect do
        raise described_class, 'SSL certificate verification failed'
      end.to raise_error(described_class, 'SSL certificate verification failed')
    end
  end

  describe 'validation error scenarios' do
    it 'handles missing required parameters' do
      expect do
        raise described_class, 'Missing required parameter: pub_key'
      end.to raise_error(described_class, 'Missing required parameter: pub_key')
    end

    it 'handles invalid parameter format' do
      expect do
        raise described_class, 'Invalid parameter format: store must be "auto", true, or false'
      end.to raise_error(described_class, 'Invalid parameter format: store must be "auto", true, or false')
    end

    it 'handles multiple validation errors' do
      errors = [
        'pub_key: required parameter missing',
        'file: must be a valid file object',
        'store: invalid value provided'
      ]
      message = errors.join('; ')

      expect do
        raise described_class, message
      end.to raise_error(described_class, message)
    end
  end

  describe 'upload-specific error scenarios' do
    it 'handles multipart upload errors' do
      expect do
        raise described_class, 'Multipart upload failed: chunk 3 of 10 upload error'
      end.to raise_error(described_class, 'Multipart upload failed: chunk 3 of 10 upload error')
    end

    it 'handles file corruption errors' do
      expect do
        raise described_class, 'File corruption detected during upload verification'
      end.to raise_error(described_class, 'File corruption detected during upload verification')
    end

    it 'handles concurrent upload errors' do
      expect do
        raise described_class, 'Concurrent upload limit exceeded: max 10 simultaneous uploads'
      end.to raise_error(described_class, 'Concurrent upload limit exceeded: max 10 simultaneous uploads')
    end
  end

  describe 'message formatting' do
    it 'preserves JSON error responses' do
      json_response = '{"error":"file_not_found","detail":"File with UUID abc123 does not exist","status":404}'
      error = described_class.new(json_response)
      expect(error.message).to eq(json_response)
    end

    it 'preserves structured error messages' do
      structured_message = "API Request Failed:\n  " \
                           "Endpoint: /files/\n  " \
                           "Method: POST\n  " \
                           "Status: 400\n  " \
                           'Error: Invalid file format'
      error = described_class.new(structured_message)
      expect(error.message).to eq(structured_message)
    end

    it 'handles multi-line error details' do
      multi_line = "Request validation failed:\n" \
                   "- pub_key is required\n" \
                   "- file parameter missing\n" \
                   '- store value invalid'
      error = described_class.new(multi_line)
      expect(error.message).to include('Request validation failed')
      expect(error.message).to include('pub_key is required')
      expect(error.message).to include('store value invalid')
    end
  end

  describe 'backtrace handling' do
    it 'preserves backtrace information' do
      raise described_class, 'Request failed'
    rescue described_class => e
      expect(e.backtrace).to be_an(Array)
      expect(e.backtrace.first).to include(__FILE__)
    end

    it 'maintains stack trace across rescue and re-raise' do
      original_backtrace = nil

      begin
        begin
          raise described_class, 'Original error'
        rescue described_class => e
          original_backtrace = e.backtrace
          raise e
        end
      rescue described_class => e
        expect(e.backtrace).to eq(original_backtrace)
      end
    end
  end
end

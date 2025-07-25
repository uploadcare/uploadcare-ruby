# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::ErrorHandler do
  let(:test_class) do
    Class.new do
      include Uploadcare::ErrorHandler
    end
  end

  let(:handler) { test_class.new }

  describe '#handle_error' do
    let(:error) { double('error', response: response) }

    context 'with JSON error response' do
      let(:response) do
        {
          status: 400,
          body: '{"detail": "Invalid public key"}'
        }
      end

      it 'raises RequestError with detail message' do
        expect { handler.handle_error(error) }.to raise_error(
          Uploadcare::Exception::RequestError,
          'Invalid public key'
        )
      end
    end

    context 'with JSON error response containing multiple fields' do
      let(:response) do
        {
          status: 422,
          body: '{"field1": "error1", "field2": "error2"}'
        }
      end

      it 'raises RequestError with combined message' do
        expect { handler.handle_error(error) }.to raise_error(
          Uploadcare::Exception::RequestError,
          'field1: error1; field2: error2'
        )
      end
    end

    context 'with invalid JSON response' do
      let(:response) do
        {
          status: 500,
          body: 'Internal Server Error'
        }
      end

      it 'raises RequestError with raw body' do
        expect { handler.handle_error(error) }.to raise_error(
          Uploadcare::Exception::RequestError,
          'Internal Server Error'
        )
      end
    end

    context 'with upload API error (status 200)' do
      let(:response) do
        {
          status: 200,
          body: '{"error": "File size exceeds limit"}'
        }
      end

      it 'catches upload error and raises RequestError' do
        expect { handler.handle_error(error) }.to raise_error(
          Uploadcare::Exception::RequestError,
          'File size exceeds limit'
        )
      end
    end

    context 'with successful upload response (status 200, no error)' do
      let(:response) do
        {
          status: 200,
          body: '{"uuid": "12345", "size": 1024}'
        }
      end

      it 'raises RequestError with combined message' do
        expect { handler.handle_error(error) }.to raise_error(
          Uploadcare::Exception::RequestError,
          'uuid: 12345; size: 1024'
        )
      end
    end

    context 'with empty response body' do
      let(:response) do
        {
          status: 403,
          body: ''
        }
      end

      it 'raises RequestError with empty message' do
        expect { handler.handle_error(error) }.to raise_error(
          Uploadcare::Exception::RequestError,
          ''
        )
      end
    end

    context 'with nil response body' do
      let(:response) do
        {
          status: 404,
          body: nil
        }
      end

      it 'raises RequestError with empty string' do
        expect { handler.handle_error(error) }.to raise_error(
          Uploadcare::Exception::RequestError,
          ''
        )
      end
    end

    context 'with array response' do
      let(:response) do
        {
          status: 400,
          body: '["error1", "error2"]'
        }
      end

      it 'raises RequestError with array string representation' do
        expect { handler.handle_error(error) }.to raise_error(
          Uploadcare::Exception::RequestError
        ) do |error|
          expect(error.message).to include('0:')
          expect(error.message).to include('error1')
          expect(error.message).to include('1:')
          expect(error.message).to include('error2')
        end
      end
    end
  end

  describe '#catch_upload_errors' do
    context 'with status 200 and error field' do
      it 'raises RequestError' do
        response = {
          status: 200,
          body: '{"error": "Upload failed", "other": "data"}'
        }

        expect { handler.send(:catch_upload_errors, response) }.to raise_error(
          Uploadcare::Exception::RequestError,
          'Upload failed'
        )
      end
    end

    context 'with status 200 and no error field' do
      it 'does not raise error' do
        response = {
          status: 200,
          body: '{"success": true}'
        }

        expect { handler.send(:catch_upload_errors, response) }.not_to raise_error
      end
    end

    context 'with non-200 status' do
      it 'does not raise error' do
        response = {
          status: 400,
          body: '{"error": "Bad request"}'
        }

        expect { handler.send(:catch_upload_errors, response) }.not_to raise_error
      end
    end

    context 'with non-JSON response' do
      it 'does not raise error' do
        response = {
          status: 200,
          body: 'not json'
        }

        # Should not raise error from catch_upload_errors itself
        expect { handler.send(:catch_upload_errors, response) }.not_to raise_error
      end
    end
  end
end
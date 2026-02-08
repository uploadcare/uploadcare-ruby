# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  RSpec.describe ErrorHandler do
    let(:test_class) do
      Class.new do
        include Uploadcare::ErrorHandler
      end
    end
    let(:handler) { test_class.new }

    describe '#handle_error' do
      context 'with 400 Bad Request' do
        let(:error) do
          double('Error', response: {
                   status: 400,
                   body: '{"detail": "Invalid request parameters"}'
                 })
        end

        it 'raises InvalidRequestError' do
          expect do
            handler.handle_error(error)
          end.to raise_error(Uploadcare::Exception::InvalidRequestError, 'Invalid request parameters')
        end
      end

      context 'with 404 Not Found' do
        let(:error) do
          double('Error', response: {
                   status: 404,
                   body: '{"detail": "Resource not found"}'
                 })
        end

        it 'raises NotFoundError' do
          expect do
            handler.handle_error(error)
          end.to raise_error(Uploadcare::Exception::NotFoundError, 'Resource not found')
        end
      end

      context 'with other error status' do
        let(:error) do
          double('Error', response: {
                   status: 500,
                   body: '{"detail": "Internal server error"}'
                 })
        end

        it 'raises RequestError' do
          expect do
            handler.handle_error(error)
          end.to raise_error(Uploadcare::Exception::RequestError, 'Internal server error')
        end
      end

      context 'with 200 status but error in body' do
        let(:error) do
          double('Error', response: {
                   status: 200,
                   body: '{"error": "Upload failed"}'
                 })
        end

        it 'raises RequestError for upload API errors' do
          expect do
            handler.handle_error(error)
          end.to raise_error(Uploadcare::Exception::RequestError, 'Upload failed')
        end
      end

      context 'with non-JSON response body' do
        let(:error) do
          double('Error', response: {
                   status: 400,
                   body: 'Plain text error message'
                 })
        end

        it 'uses raw body as error message' do
          expect do
            handler.handle_error(error)
          end.to raise_error(Uploadcare::Exception::InvalidRequestError, 'Plain text error message')
        end
      end

      context 'with multiple error fields' do
        let(:error) do
          double('Error', response: {
                   status: 400,
                   body: '{"field1": "error1", "field2": "error2"}'
                 })
        end

        it 'combines error fields' do
          expect do
            handler.handle_error(error)
          end.to raise_error(Uploadcare::Exception::InvalidRequestError, /field1: error1.*field2: error2/)
        end
      end
    end

    describe '#extract_error_message' do
      it 'extracts detail field from JSON' do
        response = { body: '{"detail": "Error message"}' }
        message = handler.send(:extract_error_message, response)

        expect(message).to eq('Error message')
      end

      it 'combines multiple fields when no detail' do
        response = { body: '{"error": "Error 1", "message": "Error 2"}' }
        message = handler.send(:extract_error_message, response)

        expect(message).to include('error: Error 1')
        expect(message).to include('message: Error 2')
      end

      it 'returns raw body for invalid JSON' do
        response = { body: 'Not JSON' }
        message = handler.send(:extract_error_message, response)

        expect(message).to eq('Not JSON')
      end

      it 'handles empty body' do
        response = { body: '' }
        message = handler.send(:extract_error_message, response)

        expect(message).to eq('')
      end
    end

    describe '#raise_status_error' do
      it 'raises InvalidRequestError for 400' do
        expect do
          handler.send(:raise_status_error, 400, 'Bad request')
        end.to raise_error(Uploadcare::Exception::InvalidRequestError, 'Bad request')
      end

      it 'raises NotFoundError for 404' do
        expect do
          handler.send(:raise_status_error, 404, 'Not found')
        end.to raise_error(Uploadcare::Exception::NotFoundError, 'Not found')
      end

      it 'raises RequestError for other statuses' do
        expect do
          handler.send(:raise_status_error, 500, 'Server error')
        end.to raise_error(Uploadcare::Exception::RequestError, 'Server error')
      end
    end

    describe '#catch_upload_errors' do
      it 'raises error for 200 status with error in body' do
        response = { status: 200, body: '{"error": "Upload failed"}' }

        expect do
          handler.send(:catch_upload_errors, response)
        end.to raise_error(Uploadcare::Exception::RequestError, 'Upload failed')
      end

      it 'does not raise for 200 status without error' do
        response = { status: 200, body: '{"success": true}' }

        expect do
          handler.send(:catch_upload_errors, response)
        end.not_to raise_error
      end

      it 'does not raise for non-200 status' do
        response = { status: 400, body: '{"error": "Bad request"}' }

        expect do
          handler.send(:catch_upload_errors, response)
        end.not_to raise_error
      end

      it 'handles non-hash response body' do
        response = { status: 200, body: '["array", "response"]' }

        expect do
          handler.send(:catch_upload_errors, response)
        end.not_to raise_error
      end
    end
  end
end

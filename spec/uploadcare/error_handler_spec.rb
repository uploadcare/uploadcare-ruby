# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::ErrorHandler do
  let(:dummy_class) do
    Class.new do
      include Uploadcare::ErrorHandler
    end
  end
  let(:instance) { dummy_class.new }

  describe '.included' do
    it 'includes the Exception module' do
      expect(dummy_class.ancestors).to include(Uploadcare::Exception)
    end
  end

  describe '#handle_error' do
    let(:error_response) do
      double('error', response: response)
    end

    context 'with standard JSON error response' do
      let(:response) do
        {
          status: 400,
          body: '{"detail": "Invalid file format"}'
        }
      end

      it 'raises RequestError with the detail message' do
        expect { instance.handle_error(error_response) }
          .to raise_error(Uploadcare::Exception::RequestError, 'Invalid file format')
      end
    end

    context 'with multiple field errors in JSON response' do
      let(:response) do
        {
          status: 400,
          body: '{"pub_key": ["This field is required"], "file": ["Invalid file type"]}'
        }
      end

      it 'raises RequestError with formatted field errors' do
        expected_message = 'pub_key: ["This field is required"]; file: ["Invalid file type"]'
        expect { instance.handle_error(error_response) }
          .to raise_error(Uploadcare::Exception::RequestError, expected_message)
      end
    end

    context 'with both detail and field errors' do
      let(:response) do
        {
          status: 400,
          body: '{"detail": "Validation failed", "file": ["Required field"]}'
        }
      end

      it 'prioritizes the detail message' do
        expect { instance.handle_error(error_response) }
          .to raise_error(Uploadcare::Exception::RequestError, 'Validation failed')
      end
    end

    context 'with non-JSON response body' do
      let(:response) do
        {
          status: 500,
          body: 'Internal Server Error'
        }
      end

      it 'raises RequestError with the raw body' do
        expect { instance.handle_error(error_response) }
          .to raise_error(Uploadcare::Exception::RequestError, 'Internal Server Error')
      end
    end

    context 'with empty response body' do
      let(:response) do
        {
          status: 500,
          body: ''
        }
      end

      it 'raises RequestError with empty string' do
        expect { instance.handle_error(error_response) }
          .to raise_error(Uploadcare::Exception::RequestError, '')
      end
    end

    context 'with nil response body' do
      let(:response) do
        {
          status: 500,
          body: nil
        }
      end

      it 'raises RequestError with empty string' do
        expect { instance.handle_error(error_response) }
          .to raise_error(Uploadcare::Exception::RequestError, '')
      end
    end

    context 'with malformed JSON response' do
      let(:response) do
        {
          status: 400,
          body: '{"invalid": json}'
        }
      end

      it 'raises RequestError with the raw body due to JSON parse error' do
        expect { instance.handle_error(error_response) }
          .to raise_error(Uploadcare::Exception::RequestError, '{"invalid": json}')
      end
    end

    context 'with upload API error (status 200 but contains error)' do
      let(:response) do
        {
          status: 200,
          body: '{"error": "Upload failed: file too large"}'
        }
      end

      it 'raises RequestError with the upload error message' do
        expect { instance.handle_error(error_response) }
          .to raise_error(Uploadcare::Exception::RequestError, 'Upload failed: file too large')
      end
    end

    context 'with upload API success (status 200 without error)' do
      let(:response) do
        {
          status: 200,
          body: '{"file": "file-uuid"}'
        }
      end

      it 'raises RequestError with the response body formatted as field errors' do
        expect { instance.handle_error(error_response) }
          .to raise_error(Uploadcare::Exception::RequestError, 'file: file-uuid')
      end
    end

    context 'with upload API non-hash response (status 200)' do
      let(:response) do
        {
          status: 200,
          body: '"string response"'
        }
      end

      it 'raises RequestError with the string response' do
        expect { instance.handle_error(error_response) }
          .to raise_error(Uploadcare::Exception::RequestError, 'string response')
      end
    end

    context 'with upload API array response (status 200)' do
      let(:response) do
        {
          status: 200,
          body: '["item1", "item2"]'
        }
      end

      it 'raises RequestError with the array response as string' do
        expect { instance.handle_error(error_response) }
          .to raise_error(Uploadcare::Exception::RequestError, '["item1", "item2"]')
      end
    end

    context 'with upload API malformed JSON (status 200)' do
      let(:response) do
        {
          status: 200,
          body: '{"malformed": json'
        }
      end

      it 'raises RequestError with the raw body due to JSON parse error' do
        expect { instance.handle_error(error_response) }
          .to raise_error(Uploadcare::Exception::RequestError, '{"malformed": json')
      end
    end
  end

  describe '#catch_upload_errors (private method)' do
    context 'when testing private method behavior through handle_error' do
      context 'with non-200 status code' do
        let(:error_response) do
          double('error', response: { status: 404, body: '{"detail": "Not found"}' })
        end

        it 'does not trigger upload error handling' do
          expect { instance.handle_error(error_response) }
            .to raise_error(Uploadcare::Exception::RequestError, 'Not found')
        end
      end

      context 'with status 200 and error field' do
        let(:error_response) do
          double('error', response: { status: 200, body: '{"error": "Upload error message"}' })
        end

        it 'detects and raises upload errors' do
          expect { instance.handle_error(error_response) }
            .to raise_error(Uploadcare::Exception::RequestError, 'Upload error message')
        end
      end

      context 'with status 200 and empty error field' do
        let(:error_response) do
          double('error', response: { status: 200, body: '{"error": ""}' })
        end

        it 'does not raise for empty error' do
          expect { instance.handle_error(error_response) }
            .to raise_error(Uploadcare::Exception::RequestError, 'error: ')
        end
      end

      context 'with status 200 and null error field' do
        let(:error_response) do
          double('error', response: { status: 200, body: '{"error": null}' })
        end

        it 'does not raise for null error' do
          expect { instance.handle_error(error_response) }
            .to raise_error(Uploadcare::Exception::RequestError, 'error: ')
        end
      end

      context 'with status 200 and false error field' do
        let(:error_response) do
          double('error', response: { status: 200, body: '{"error": false}' })
        end

        it 'does not raise for falsey error' do
          expect { instance.handle_error(error_response) }
            .to raise_error(Uploadcare::Exception::RequestError, 'error: false')
        end
      end
    end
  end

  describe 'error message formatting' do
    context 'with complex nested JSON errors' do
      let(:error_response) do
        double('error', response: {
                 status: 400,
                 body: '{"validation": {"file": ["Required", "Invalid format"], "size": ["Too large"]}}'
               })
      end

      it 'formats nested errors correctly' do
        expected = 'validation: {"file"=>["Required", "Invalid format"], "size"=>["Too large"]}'
        expect { instance.handle_error(error_response) }
          .to raise_error(Uploadcare::Exception::RequestError, expected)
      end
    end

    context 'with array error values' do
      let(:error_response) do
        double('error', response: {
                 status: 400,
                 body: '{"errors": ["Error 1", "Error 2", "Error 3"]}'
               })
      end

      it 'formats array errors correctly' do
        expect { instance.handle_error(error_response) }
          .to raise_error(Uploadcare::Exception::RequestError, 'errors: ["Error 1", "Error 2", "Error 3"]')
      end
    end

    context 'with numeric error values' do
      let(:error_response) do
        double('error', response: {
                 status: 400,
                 body: '{"status_code": 400, "retry_after": 60}'
               })
      end

      it 'formats numeric errors correctly' do
        expected = 'status_code: 400; retry_after: 60'
        expect { instance.handle_error(error_response) }
          .to raise_error(Uploadcare::Exception::RequestError, expected)
      end
    end
  end

  describe 'edge cases and error scenarios' do
    context 'when response object is malformed' do
      let(:error_response) do
        double('error', response: nil)
      end

      it 'handles nil response gracefully' do
        expect { instance.handle_error(error_response) }
          .to raise_error(NoMethodError)
      end
    end

    context 'when response hash is missing keys' do
      let(:error_response) do
        double('error', response: {})
      end

      it 'handles missing status key' do
        expect { instance.handle_error(error_response) }
          .to raise_error(Uploadcare::Exception::RequestError, '')
      end
    end

    context 'with very large JSON response' do
      let(:large_data) { { 'data' => 'x' * 10_000 } }
      let(:error_response) do
        double('error', response: {
                 status: 400,
                 body: large_data.to_json
               })
      end

      it 'handles large responses correctly' do
        expected = "data: #{'x' * 10_000}"
        expect { instance.handle_error(error_response) }
          .to raise_error(Uploadcare::Exception::RequestError, expected)
      end
    end

    context 'with Unicode characters in error messages' do
      let(:error_response) do
        double('error', response: {
                 status: 400,
                 body: '{"detail": "Файл не найден 🔍"}'
               })
      end

      it 'handles Unicode characters correctly' do
        expect { instance.handle_error(error_response) }
          .to raise_error(Uploadcare::Exception::RequestError, 'Файл не найден 🔍')
      end
    end
  end

  describe 'module integration' do
    it 'provides access to all exception classes' do
      expect(instance).to respond_to(:handle_error)
      expect(dummy_class.ancestors).to include(Uploadcare::Exception)
    end

    it 'allows access to exception classes through the module' do
      expect(Uploadcare::Exception::RequestError).to be < StandardError
      expect(Uploadcare::Exception::AuthError).to be < StandardError
      expect(Uploadcare::Exception::ThrottleError).to be < StandardError
    end
  end
end

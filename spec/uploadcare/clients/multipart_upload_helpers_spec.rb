# frozen_string_literal: true

require 'spec_helper'
require 'mime/types'

RSpec.describe Uploadcare::MultipartUploadHelpers do
  let(:dummy_class) do
    Class.new do
      include Uploadcare::MultipartUploadHelpers
    end
  end
  let(:instance) { dummy_class.new }
  let(:mock_file) { double('file', size: 1024, path: '/path/to/test.pdf') }

  before do
    allow(Uploadcare).to receive(:configuration).and_return(
      double('configuration',
             public_key: 'pub_test_key',
             sign_uploads: false,
             logger: nil)
    )
  end

  describe '#generate_upload_params' do
    it 'includes public key by default' do
      params = instance.send(:generate_upload_params)
      expect(params['UPLOADCARE_PUB_KEY']).to eq('pub_test_key')
    end

    it 'includes store parameter when auto' do
      params = instance.send(:generate_upload_params, store: 'auto')
      expect(params['UPLOADCARE_STORE']).to eq('auto')
    end

    it 'includes store parameter when true' do
      params = instance.send(:generate_upload_params, store: true)
      expect(params['UPLOADCARE_STORE']).to eq('true')
    end

    it 'includes store parameter when false' do
      params = instance.send(:generate_upload_params, store: false)
      expect(params['UPLOADCARE_STORE']).to eq('false')
    end

    it 'includes store parameter when 1' do
      params = instance.send(:generate_upload_params, store: 1)
      expect(params['UPLOADCARE_STORE']).to eq('true')
    end

    it 'includes store parameter when 0' do
      params = instance.send(:generate_upload_params, store: 0)
      expect(params['UPLOADCARE_STORE']).to eq('false')
    end

    it 'defaults store to auto when not provided' do
      params = instance.send(:generate_upload_params)
      expect(params['UPLOADCARE_STORE']).to eq('auto')
    end

    it 'removes nil values from parameters' do
      allow(instance).to receive(:generate_metadata_params).and_return('meta_key' => nil, 'valid_key' => 'value')
      params = instance.send(:generate_upload_params)
      expect(params).not_to have_key('meta_key')
      expect(params['valid_key']).to eq('value')
    end

    context 'when uploads are signed' do
      before do
        allow(Uploadcare.configuration).to receive(:sign_uploads).and_return(true)
      end

      context 'when SignatureGenerator is available' do
        before do
          signature_generator = double('SignatureGenerator')
          allow(signature_generator).to receive(:call).and_return('test_signature')
          stub_const('Uploadcare::Param::Upload::SignatureGenerator', signature_generator)
        end

        it 'includes signature parameter' do
          params = instance.send(:generate_upload_params)
          expect(params['signature']).to eq('test_signature')
        end
      end

      context 'when SignatureGenerator is not available' do
        before do
          hide_const('Uploadcare::Param::Upload::SignatureGenerator')
        end

        it 'does not include signature parameter' do
          params = instance.send(:generate_upload_params)
          expect(params).not_to have_key('signature')
        end

        it 'logs warning when logger is available' do
          logger = double('logger')
          allow(Uploadcare.configuration).to receive(:logger).and_return(logger)
          expect(logger).to receive(:warn).with('Upload signing is enabled but SignatureGenerator is not available')
          instance.send(:generate_upload_params)
        end
      end

      context 'when SignatureGenerator raises an error' do
        before do
          signature_generator = double('SignatureGenerator')
          allow(signature_generator).to receive(:call).and_raise(StandardError.new('Signature error'))
          stub_const('Uploadcare::Param::Upload::SignatureGenerator', signature_generator)
        end

        it 'does not include signature parameter' do
          params = instance.send(:generate_upload_params)
          expect(params).not_to have_key('signature')
        end

        it 'logs error when logger is available' do
          logger = double('logger')
          allow(Uploadcare.configuration).to receive(:logger).and_return(logger)
          expect(logger).to receive(:error).with('Failed to generate upload signature: Signature error')
          instance.send(:generate_upload_params)
        end
      end
    end

    context 'with metadata' do
      it 'includes metadata parameters' do
        allow(instance).to receive(:generate_metadata_params).and_return('meta_key1' => 'value1', 'meta_key2' => 'value2')
        params = instance.send(:generate_upload_params, metadata: { key1: 'value1', key2: 'value2' })
        expect(params['meta_key1']).to eq('value1')
        expect(params['meta_key2']).to eq('value2')
      end
    end
  end

  describe '#generate_upload_signature' do
    context 'when signing is disabled' do
      before do
        allow(Uploadcare.configuration).to receive(:sign_uploads).and_return(false)
      end

      it 'is not called when signing is disabled' do
        params = instance.send(:generate_upload_params)
        expect(params).not_to have_key('signature')
      end
    end

    context 'when SignatureGenerator is available' do
      before do
        signature_generator = double('SignatureGenerator')
        allow(signature_generator).to receive(:call).and_return('generated_signature')
        stub_const('Uploadcare::Param::Upload::SignatureGenerator', signature_generator)
      end

      it 'returns the generated signature' do
        signature = instance.send(:generate_upload_signature)
        expect(signature).to eq('generated_signature')
      end
    end

    context 'when SignatureGenerator is not defined' do
      before do
        hide_const('Uploadcare::Param::Upload::SignatureGenerator')
      end

      it 'returns nil' do
        signature = instance.send(:generate_upload_signature)
        expect(signature).to be_nil
      end
    end

    context 'when SignatureGenerator raises an error' do
      before do
        signature_generator = double('SignatureGenerator')
        allow(signature_generator).to receive(:call).and_raise(RuntimeError.new('Test error'))
        stub_const('Uploadcare::Param::Upload::SignatureGenerator', signature_generator)
      end

      it 'returns nil' do
        signature = instance.send(:generate_upload_signature)
        expect(signature).to be_nil
      end

      it 'logs the error when logger is available' do
        logger = double('logger')
        allow(Uploadcare.configuration).to receive(:logger).and_return(logger)
        expect(logger).to receive(:error).with('Failed to generate upload signature: Test error')
        instance.send(:generate_upload_signature)
      end
    end
  end

  describe '#multipart_file_params' do
    let(:file_with_original_filename) do
      double('file',
             size: 2048,
             path: '/path/to/document.pdf',
             original_filename: 'my_document.pdf')
    end

    let(:file_without_original_filename) do
      double('file',
             size: 1024,
             path: '/path/to/image.jpg')
    end

    before do
      allow(MIME::Types).to receive(:type_for).with('/path/to/document.pdf')
                                              .and_return([double('mime_type', content_type: 'application/pdf')])
      allow(MIME::Types).to receive(:type_for).with('/path/to/image.jpg')
                                              .and_return([double('mime_type', content_type: 'image/jpeg')])
      allow(MIME::Types).to receive(:type_for).with('/path/to/unknown.xyz')
                                              .and_return([])
      allow(File).to receive(:basename).with('/path/to/document.pdf').and_return('document.pdf')
      allow(File).to receive(:basename).with('/path/to/image.jpg').and_return('image.jpg')
      allow(File).to receive(:basename).with('/path/to/unknown.xyz').and_return('unknown.xyz')
    end

    it 'uses original_filename when available' do
      params = instance.send(:multipart_file_params, file_with_original_filename)
      expect(params['filename']).to eq('my_document.pdf')
    end

    it 'uses basename when original_filename is not available' do
      params = instance.send(:multipart_file_params, file_without_original_filename)
      expect(params['filename']).to eq('image.jpg')
    end

    it 'includes file size as string' do
      params = instance.send(:multipart_file_params, file_with_original_filename)
      expect(params['size']).to eq('2048')
    end

    it 'detects MIME type correctly' do
      params = instance.send(:multipart_file_params, file_with_original_filename)
      expect(params['content_type']).to eq('application/pdf')
    end

    it 'falls back to default MIME type for unknown files' do
      unknown_file = double('file', size: 512, path: '/path/to/unknown.xyz')
      params = instance.send(:multipart_file_params, unknown_file)
      expect(params['content_type']).to eq('application/octet-stream')
    end

    it 'returns all required parameters' do
      params = instance.send(:multipart_file_params, file_with_original_filename)
      expect(params.keys).to contain_exactly('filename', 'size', 'content_type')
    end
  end

  describe '#multipart_start_params' do
    let(:options) { { store: true, metadata: { key: 'value' } } }

    before do
      allow(instance).to receive(:generate_upload_params).with(options)
                                                         .and_return('UPLOADCARE_PUB_KEY' => 'pub_key', 'UPLOADCARE_STORE' => 'true')
      allow(instance).to receive(:multipart_file_params).with(mock_file)
                                                        .and_return('filename' => 'test.pdf', 'size' => '1024', 'content_type' => 'application/pdf')
    end

    it 'merges upload params with file params' do
      params = instance.send(:multipart_start_params, mock_file, options)

      expect(params['UPLOADCARE_PUB_KEY']).to eq('pub_key')
      expect(params['UPLOADCARE_STORE']).to eq('true')
      expect(params['filename']).to eq('test.pdf')
      expect(params['size']).to eq('1024')
      expect(params['content_type']).to eq('application/pdf')
    end

    it 'calls generate_upload_params with provided options' do
      expect(instance).to receive(:generate_upload_params).with(options)
      instance.send(:multipart_start_params, mock_file, options)
    end

    it 'calls multipart_file_params with provided file object' do
      expect(instance).to receive(:multipart_file_params).with(mock_file)
      instance.send(:multipart_start_params, mock_file, options)
    end

    it 'handles empty options' do
      allow(instance).to receive(:generate_upload_params).with({}).and_return({ 'UPLOADCARE_PUB_KEY' => 'test' })
      allow(instance).to receive(:multipart_file_params).and_return({ 'filename' => 'test.pdf' })
      expect(instance).to receive(:generate_upload_params).with({})
      instance.send(:multipart_start_params, mock_file, {})
    end

    it 'handles nil options' do
      allow(instance).to receive(:generate_upload_params).with(nil).and_return({ 'UPLOADCARE_PUB_KEY' => 'test' })
      allow(instance).to receive(:multipart_file_params).and_return({ 'filename' => 'test.pdf' })
      expect(instance).to receive(:generate_upload_params).with(nil)
      instance.send(:multipart_start_params, mock_file, nil)
    end
  end

  describe 'private method #store_value' do
    it 'converts true to "true"' do
      params = instance.send(:generate_upload_params, store: true)
      expect(params['UPLOADCARE_STORE']).to eq('true')
    end

    it 'converts false to "false"' do
      params = instance.send(:generate_upload_params, store: false)
      expect(params['UPLOADCARE_STORE']).to eq('false')
    end

    it 'converts 1 to "true"' do
      params = instance.send(:generate_upload_params, store: 1)
      expect(params['UPLOADCARE_STORE']).to eq('true')
    end

    it 'converts 0 to "false"' do
      params = instance.send(:generate_upload_params, store: 0)
      expect(params['UPLOADCARE_STORE']).to eq('false')
    end

    it 'passes through string values' do
      params = instance.send(:generate_upload_params, store: 'auto')
      expect(params['UPLOADCARE_STORE']).to eq('auto')
    end

    it 'defaults to "auto" when nil' do
      params = instance.send(:generate_upload_params, store: nil)
      expect(params['UPLOADCARE_STORE']).to eq('auto')
    end

    it 'defaults to "auto" when not provided' do
      params = instance.send(:generate_upload_params)
      expect(params['UPLOADCARE_STORE']).to eq('auto')
    end
  end

  describe 'private method #generate_metadata_params' do
    context 'when metadata is provided' do
      it 'returns empty hash when metadata is nil' do
        params = instance.send(:generate_upload_params, metadata: nil)
        expect(params.keys.grep(/^metadata\[/)).to be_empty
      end

      it 'returns empty hash when metadata is empty' do
        params = instance.send(:generate_upload_params, metadata: {})
        expect(params.keys.grep(/^metadata\[/)).to be_empty
      end

      it 'handles string keys in metadata' do
        params = instance.send(:generate_upload_params, metadata: { 'key1' => 'value1' })
        expect(params['metadata[key1]']).to eq('value1')
      end

      it 'handles symbol keys in metadata' do
        params = instance.send(:generate_upload_params, metadata: { key1: 'value1' })
        expect(params['metadata[key1]']).to eq('value1')
      end
    end
  end

  describe 'integration scenarios' do
    context 'with complex file objects' do
      let(:tempfile) do
        double('tempfile',
               size: 4096,
               path: '/tmp/upload12345.tmp',
               original_filename: 'user_document.pdf')
      end

      before do
        allow(MIME::Types).to receive(:type_for).with('/tmp/upload12345.tmp')
                                                .and_return([double('mime_type', content_type: 'application/pdf')])
      end

      it 'handles tempfile objects correctly' do
        params = instance.send(:multipart_file_params, tempfile)
        expect(params['filename']).to eq('user_document.pdf')
        expect(params['size']).to eq('4096')
        expect(params['content_type']).to eq('application/pdf')
      end
    end

    context 'with uploaded file objects' do
      let(:uploaded_file) do
        double('uploaded_file',
               size: 8192,
               path: '/uploads/file.jpg',
               original_filename: 'vacation_photo.jpg')
      end

      before do
        allow(MIME::Types).to receive(:type_for).with('/uploads/file.jpg')
                                                .and_return([double('mime_type', content_type: 'image/jpeg')])
      end

      it 'handles uploaded file objects correctly' do
        params = instance.send(:multipart_file_params, uploaded_file)
        expect(params['filename']).to eq('vacation_photo.jpg')
        expect(params['size']).to eq('8192')
        expect(params['content_type']).to eq('image/jpeg')
      end
    end

    context 'error handling in file parameter extraction' do
      let(:broken_file) do
        double('broken_file').tap do |file|
          allow(file).to receive(:size).and_raise(StandardError.new('File access error'))
          allow(file).to receive(:path).and_return('/path/to/file.txt')
        end
      end

      it 'propagates file access errors' do
        expect do
          instance.send(:multipart_file_params, broken_file)
        end.to raise_error(StandardError, 'File access error')
      end
    end
  end

  describe 'configuration integration' do
    context 'when public key is missing' do
      before do
        allow(Uploadcare.configuration).to receive(:public_key).and_return(nil)
      end

      it 'includes nil public key' do
        params = instance.send(:generate_upload_params)
        expect(params['UPLOADCARE_PUB_KEY']).to be_nil
      end
    end

    context 'when configuration is not available' do
      before do
        allow(Uploadcare).to receive(:configuration).and_raise(StandardError.new('Configuration error'))
      end

      it 'propagates configuration errors' do
        expect do
          instance.send(:generate_upload_params)
        end.to raise_error(StandardError, 'Configuration error')
      end
    end
  end

  describe 'module inclusion' do
    it 'includes all required methods as private' do
      expect(instance.private_methods).to include(:generate_upload_params)
      expect(instance.private_methods).to include(:generate_upload_signature)
      expect(instance.private_methods).to include(:multipart_file_params)
      expect(instance.private_methods).to include(:multipart_start_params)
    end

    it 'does not expose methods as public' do
      expect(instance.public_methods).not_to include(:generate_upload_params)
      expect(instance.public_methods).not_to include(:generate_upload_signature)
      expect(instance.public_methods).not_to include(:multipart_file_params)
      expect(instance.public_methods).not_to include(:multipart_start_params)
    end
  end
end

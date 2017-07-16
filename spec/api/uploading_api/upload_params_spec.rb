require 'spec_helper'

describe Uploadcare::UploadingApi::UploadParams do
  shared_examples 'handles store flag' do |key_name|
    let(:true_value) { 1 }
    let(:false_value) { 0 }

    context 'when neither global nor per-request store option is set' do
      it { is_expected.not_to include(key_name) }
    end

    context 'accepts :auto value in :store option' do
      before { request_options.merge!(store: :auto) }
      it { is_expected.to include(key_name => 'auto') }
    end

    context 'when only global :autostore option is set' do
      context 'to true' do
        before { global_options.merge!(autostore: true) }
        it { is_expected.to include(key_name => true_value) }
      end

      context 'to false' do
        before { global_options.merge!(autostore: false) }
        it { is_expected.to include(key_name => false_value) }
      end
    end

    context 'per-request :store option is set' do
      context 'to true' do
        before { request_options.merge!(store: true) }
        it { is_expected.to include(key_name => true_value) }
      end

      context 'to false' do
        before { request_options.merge!(store: false) }
        it { is_expected.to include(key_name => false_value) }
      end
    end

    context 'when both global and per-request store options are set' do
      before do
        global_options.merge!(autostore: false)
        request_options.merge!(store: true)
      end

      it 'per-request :store option has higher presidence' do
        is_expected.to include(key_name => true_value)
      end
    end
  end

  let(:global_options) { {public_key: 'test_public_key'} }
  let(:request_options) { {} }

  describe '#for_url_upload' do
    let(:url) { 'http://example.com/image.jpg' }
    subject(:upload_params) do
      described_class.new(global_options, request_options).for_url_upload(url)
    end

    it { is_expected.to include(source_url: URI.parse(url)) }
    it { is_expected.to include(pub_key: 'test_public_key') }
    it_behaves_like 'handles store flag', :store

    context 'works with https URLs' do
      let(:url) { 'https://example.com/image.jpg' }
      it { expect { upload_params }.not_to raise_error }
    end

    context 'if url is not http/https' do
      let(:url) { 'ftp://example.com/image.jpg' }
      it { expect { upload_params }.to raise_error(ArgumentError) }
    end
  end

  describe '#for_file_upload' do
    let(:files) { FILES_ARY } # contains 2 files, first is png, second is jpg
    subject(:upload_params) do
      described_class.new(global_options, request_options).for_file_upload(files)
    end

    it { is_expected.to include(UPLOADCARE_PUB_KEY: 'test_public_key') }
    it_behaves_like 'handles store flag', :UPLOADCARE_STORE

    context 'file params' do
      subject(:file_params) { upload_params.select { |k, _| k =~ /^file\[\d+\]/ }.values }

      it { expect(file_params.size).to eq(files.size) }
      it { is_expected.to all(be_a(Faraday::UploadIO)) }
      it { is_expected.to all(satisfy { |file| file.content_type =~ /image\/(png|jpeg)/}) }
    end

    context 'when any of given objects is not a File' do
      let(:files) { FILES_ARY + ['not a File'] }
      it { expect {upload_params}.to raise_error(ArgumentError) }
    end
  end
end

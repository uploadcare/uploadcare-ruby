# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Entity
    RSpec.describe File do
      subject { File }
      it 'responds to expected methods' do
        expect(subject).to respond_to(:info, :delete, :store, :local_copy, :remote_copy)
      end

      it 'represents a file as entity' do
        VCR.use_cassette('file_info') do
          uuid = '8f64f313-e6b1-4731-96c0-6751f1e7a50a'
          file = subject.info(uuid)
          expect(file).to be_a_kind_of(subject)
          expect(file).to respond_to(*File::RESPONSE_PARAMS)
          expect(file.uuid).to eq(uuid)
        end
      end

      it 'raises error for nonexistent file' do
        VCR.use_cassette('rest_file_info_fail') do
          uuid = 'nonexistent'
          expect { subject.info(uuid) }.to raise_error(RequestError)
        end
      end

      it 'raises error when trying to delete nonexistent file' do
        VCR.use_cassette('rest_file_delete_nonexistent') do
          uuid = 'nonexistent'
          expect { subject.delete(uuid) }.to raise_error(RequestError)
        end
      end

      describe 'internal_copy' do
        it 'copies file to same project' do
          VCR.use_cassette('rest_file_internal_copy') do
            file = subject.file('5632fc94-9dff-499f-a373-f69ea6f67ff8')
            file.local_copy
          end
        end
      end

      describe 'external_copy' do
        it 'copies file to remote storage' do
          VCR.use_cassette('rest_file_remote_copy') do
            target = 'uploadcare-test'
            uuid = '1b959c59-9605-4879-946f-08fdb5ea3e9d'
            file = subject.file(uuid)
            expect(file.remote_copy(target)).to match(%r{#{target}/#{uuid}/})
          end
        end

        it 'raises an error when project does not have given storage' do
          VCR.use_cassette('rest_file_external_copy') do
            file = subject.file('5632fc94-9dff-499f-a373-f69ea6f67ff8')
            # I don't have custom storage, but this error recognises what this method tries to do
            msg = 'Project has no storage with provided name.'
            expect { file.remote_copy('16d8625b4c5c4a372a8f') }.to raise_error(RequestError, msg)
          end
        end
      end

      describe 'uuid' do
        it 'returns uuid, even if only url is defined' do
          file = File.new(url: 'https://ucarecdn.com/35b7fcd7-9bca-40e1-99b1-2adcc21c405d/123.jpg')
          expect(file.uuid).to eq '35b7fcd7-9bca-40e1-99b1-2adcc21c405d'
        end
      end

      describe 'datetime_stored' do
        it 'returns datetime_stored, with deprecated warning' do
          VCR.use_cassette('file_info') do
            url = 'https://ucarecdn.com/8f64f313-e6b1-4731-96c0-6751f1e7a50a'
            file = File.new(url: url)
            logger = Uploadcare.config.logger
            file.load
            allow(logger).to receive(:warn).with('datetime_stored property has been deprecated, and will be removed without a replacement in future.')
            datetime_stored = file.datetime_stored
            expect(logger).to have_received(:warn).with('datetime_stored property has been deprecated, and will be removed without a replacement in future.')
            expect(datetime_stored).not_to be_nil
          end
        end
      end

      describe 'load' do
        it 'performs load request' do
          VCR.use_cassette('file_info') do
            url = 'https://ucarecdn.com/8f64f313-e6b1-4731-96c0-6751f1e7a50a'
            file = File.new(url: url)
            file.load
            expect(file.datetime_uploaded).not_to be_nil
          end
        end
      end

      describe 'cdn_url' do
        let(:test_uuid) { '8f64f313-e6b1-4731-96c0-6751f1e7a50a' }
        let(:file) { File.new(uuid: test_uuid) }

        before do
          # Reset any memoized config values
          allow(Uploadcare.config).to receive(:cdn_base).and_call_original
        end

        it 'generates CDN URL using cdn_base config' do
          allow(Uploadcare.config).to receive(:cdn_base).and_return(-> { 'https://example.ucarecdn.com' })

          result = file.cdn_url
          expect(result).to eq("https://example.ucarecdn.com#{test_uuid}/")
        end

        it 'handles different CDN base configurations' do
          test_cases = [
            { base: 'https://custom.cdn.com', expected: "https://custom.cdn.com#{test_uuid}/" },
            { base: 'https://subdomain.ucarecdn.com', expected: "https://subdomain.ucarecdn.com#{test_uuid}/" },
            { base: 'https://cdn.example.org', expected: "https://cdn.example.org#{test_uuid}/" }
          ]

          test_cases.each do |test_case|
            allow(Uploadcare.config).to receive(:cdn_base).and_return(-> { test_case[:base] })
            expect(file.cdn_url).to eq(test_case[:expected])
          end
        end

        it 'works with file initialized from URL' do
          url_file = File.new(url: "https://ucarecdn.com/#{test_uuid}/image.jpg")
          allow(Uploadcare.config).to receive(:cdn_base).and_return(-> { 'https://test.cdn.com' })

          result = url_file.cdn_url
          expect(result).to eq("https://test.cdn.com#{test_uuid}/")
        end

        it 'calls cdn_base each time for dynamic config updates' do
          allow(Uploadcare.config).to receive(:cdn_base).and_return(-> { 'https://first.cdn.com' })
          first_call = file.cdn_url

          allow(Uploadcare.config).to receive(:cdn_base).and_return(-> { 'https://second.cdn.com' })
          second_call = file.cdn_url

          expect(first_call).to eq("https://first.cdn.com#{test_uuid}/")
          expect(second_call).to eq("https://second.cdn.com#{test_uuid}/")
        end

        it 'handles CDN base with trailing slashes correctly' do
          test_cases = [
            { base: 'https://cdn.com/', expected: "https://cdn.com/#{test_uuid}/" },
            { base: 'https://cdn.com', expected: "https://cdn.com#{test_uuid}/" }
          ]

          test_cases.each do |test_case|
            allow(Uploadcare.config).to receive(:cdn_base).and_return(-> { test_case[:base] })
            expect(file.cdn_url).to eq(test_case[:expected])
          end
        end

        it 'includes cdn_url in RESPONSE_PARAMS' do
          expect(File::RESPONSE_PARAMS).to include(:cdn_url)
        end

        it 'works with subdomains when enabled' do
          allow(Uploadcare.config).to receive(:use_subdomains).and_return(true)
          allow(Uploadcare.config).to receive(:public_key).and_return('test_public_key')
          allow(Uploadcare.config).to receive(:cdn_base).and_return(-> { 'https://abc123def.ucarecdn.com' })

          result = file.cdn_url
          expect(result).to eq("https://abc123def.ucarecdn.com#{test_uuid}/")
        end

        it 'handles custom CNAME domains' do
          allow(Uploadcare.config).to receive(:cdn_base).and_return(-> { 'https://my-custom-domain.com' })

          result = file.cdn_url
          expect(result).to eq("https://my-custom-domain.com#{test_uuid}/")
        end

        context 'integration with real config' do
          it 'generates valid CDN URL with default config' do
            # Don't mock cdn_base to test real integration
            result = file.cdn_url

            expect(result).to be_a(String)
            expect(result).to include(test_uuid)
            expect(result).to end_with('/')
            expect(result).to match(%r{\Ahttps?://})
          end
        end
      end

      describe 'file conversion' do
        let(:url) { "https://ucarecdn.com/#{source_file_uuid}" }
        let(:file) { File.new(url: url) }

        shared_examples 'new file conversion' do
          it 'performs a convert request', :aggregate_failures do
            VCR.use_cassette(convert_cassette) do
              VCR.use_cassette(get_file_cassette) do
                expect(new_file.uuid).not_to be_empty
                expect(new_file.uuid).not_to eq source_file_uuid
              end
            end
          end
        end

        context 'when converting a document' do
          let(:source_file_uuid) { '8f64f313-e6b1-4731-96c0-6751f1e7a50a' }
          let(:new_file) { file.convert_document({ format: 'png', page: 1 }) }

          it_behaves_like 'new file conversion' do
            let(:convert_cassette) { 'document_convert_convert_many' }
            let(:get_file_cassette) { 'document_convert_file_info' }
          end
        end

        context 'when converting a video' do
          let(:source_file_uuid) { 'e30112d7-3a90-4931-b2c5-688cbb46d3ac' }
          let(:new_file) do
            file.convert_video(
              {
                format: 'ogg',
                quality: 'best',
                cut: { start_time: '0:0:0.0', length: 'end' },
                size: { resize_mode: 'change_ratio', width: '600', height: '400' },
                thumb: { N: 1, number: 2 }
              }
            )
          end

          it_behaves_like 'new file conversion' do
            let(:convert_cassette) { 'video_convert_convert_many' }
            let(:get_file_cassette) { 'video_convert_file_info' }
          end
        end
      end
    end
  end
end

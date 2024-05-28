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

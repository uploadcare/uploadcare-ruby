# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/ModuleLength
module Uploadcare
  module Entity
    RSpec.describe Addons do
      subject { Addons }

      it 'responds to expected methods' do
        methods = %i[uc_clamav_virus_scan uc_clamav_virus_scan_status ws_rekognition_detect_labels
                     ws_rekognition_detect_labels_status remove_bg remove_bg_status]
        expect(subject).to respond_to(*methods)
      end

      describe 'uc_clamav_virus_scan' do
        it 'scan the file for viruses' do
          VCR.use_cassette('uc_clamav_virus_scan') do
            uuid = 'ff4d3d37-4de0-4f6d-a7db-8cdabe7fc768'
            params = { purge_infected: false }
            response = subject.uc_clamav_virus_scan(uuid, params)
            expect(response.request_id).to eq('34abf037-5384-4e38-bad4-97dd48e79acd')
          end
        end

        it 'raises error for nonexistent file uuid' do
          VCR.use_cassette('uc_clamav_virus_scan_nonexistent_uuid') do
            uuid = 'nonexistent'
            expect { subject.uc_clamav_virus_scan(uuid) }.to raise_error(RequestError)
          end
        end
      end

      describe 'uc_clamav_virus_scan_status' do
        it 'checking the status of a virus scanned file' do
          VCR.use_cassette('uc_clamav_virus_scan_status') do
            uuid = '34abf037-5384-4e38-bad4-97dd48e79acd'
            response = subject.uc_clamav_virus_scan_status(uuid)
            expect(response.status).to eq('done')
          end
        end

        it 'raises error for nonexistent file uuid' do
          VCR.use_cassette('uc_clamav_virus_scan_status_nonexistent_uuid') do
            uuid = 'nonexistent'
            expect { subject.uc_clamav_virus_scan_status(uuid) }.to raise_error(RequestError)
          end
        end
      end

      describe 'ws_rekognition_detect_labels' do
        it 'execute aws rekognition' do
          VCR.use_cassette('ws_rekognition_detect_labels') do
            uuid = 'ff4d3d37-4de0-4f6d-a7db-8cdabe7fc768'
            response = subject.ws_rekognition_detect_labels(uuid)
            expect(response.request_id).to eq('0f4598dd-d168-4272-b49e-e7f9d2543542')
          end
        end

        it 'raises error for nonexistent file uuid' do
          VCR.use_cassette('ws_rekognition_detect_labels_nonexistent_uuid') do
            uuid = 'nonexistent'
            expect { subject.uc_clamav_virus_scan_status(uuid) }.to raise_error(RequestError)
          end
        end
      end

      describe 'ws_rekognition_detect_labels_status' do
        it 'checking the status of a recognized file' do
          VCR.use_cassette('ws_rekognition_detect_labels_status') do
            uuid = '0f4598dd-d168-4272-b49e-e7f9d2543542'
            response = subject.ws_rekognition_detect_labels_status(uuid)
            expect(response.status).to eq('done')
          end
        end

        it 'raises error for nonexistent file uuid' do
          VCR.use_cassette('ws_rekognition_detect_labels_status_nonexistent_uuid') do
            uuid = 'nonexistent'
            expect { subject.uc_clamav_virus_scan_status(uuid) }.to raise_error(RequestError)
          end
        end
      end

      describe 'remove_bg' do
        it 'execute background image removal' do
          VCR.use_cassette('remove_bg') do
            uuid = 'ff4d3d37-4de0-4f6d-a7db-8cdabe7fc768'
            params = { crop: true, type_level: '2' }
            response = subject.remove_bg(uuid, params)
            expect(response.request_id).to eq('c3446e41-9eb0-4301-aeb4-356d0fdcf9af')
          end
        end

        it 'raises error for nonexistent file uuid' do
          VCR.use_cassette('remove_bg_nonexistent_uuid') do
            uuid = 'nonexistent'
            expect { subject.uc_clamav_virus_scan_status(uuid) }.to raise_error(RequestError)
          end
        end
      end

      describe 'remove_bg_status' do
        it 'checking the status background image removal file' do
          VCR.use_cassette('remove_bg_status') do
            uuid = 'c3446e41-9eb0-4301-aeb4-356d0fdcf9af'
            response = subject.remove_bg_status(uuid)
            expect(response.status).to eq('done')
            expect(response.result).to eq({ 'file_id' => 'bc37b996-916d-4ed7-b230-fa71a4290cb3' })
          end
        end

        it 'raises error for nonexistent file uuid' do
          VCR.use_cassette('remove_bg_status_nonexistent_uuid') do
            uuid = 'nonexistent'
            expect { subject.uc_clamav_virus_scan_status(uuid) }.to raise_error(RequestError)
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength

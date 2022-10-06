# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Client
    RSpec.describe AddonsClient do
      subject { AddonsClient.new }

      describe 'uc_clamav_virus_scan' do
        it 'scans the file for viruses' do
          VCR.use_cassette('uc_clamav_virus_scan') do
            uuid = 'ff4d3d37-4de0-4f6d-a7db-8cdabe7fc768'
            params = { purge_infected: true }
            response = subject.uc_clamav_virus_scan(uuid, params)
            expect(response.success).to eq({ request_id: '34abf037-5384-4e38-bad4-97dd48e79acd' })
          end
        end
      end

      describe 'uc_clamav_virus_scan_status' do
        it 'checking the status of a virus scanned file' do
          VCR.use_cassette('uc_clamav_virus_scan_status') do
            uuid = '34abf037-5384-4e38-bad4-97dd48e79acd'
            response = subject.uc_clamav_virus_scan_status(uuid)
            expect(response.success).to eq({ status: 'done' })
          end
        end
      end

      describe 'ws_rekognition_detect_labels' do
        it 'executes aws rekognition' do
          VCR.use_cassette('ws_rekognition_detect_labels') do
            uuid = 'ff4d3d37-4de0-4f6d-a7db-8cdabe7fc768'
            response = subject.ws_rekognition_detect_labels(uuid)
            expect(response.success).to eq({ request_id: '0f4598dd-d168-4272-b49e-e7f9d2543542' })
          end
        end
      end

      describe 'ws_rekognition_detect_labels_status' do
        it 'checking the status of a recognized file' do
          VCR.use_cassette('ws_rekognition_detect_labels_status') do
            uuid = '0f4598dd-d168-4272-b49e-e7f9d2543542'
            response = subject.ws_rekognition_detect_labels_status(uuid)
            expect(response.success).to eq({ status: 'done' })
          end
        end
      end

      describe 'remove_bg' do
        it 'executes background image removal' do
          VCR.use_cassette('remove_bg') do
            uuid = 'ff4d3d37-4de0-4f6d-a7db-8cdabe7fc768'
            params = { crop: true, type_level: '2' }
            response = subject.remove_bg(uuid, params)
            expect(response.success).to eq({ request_id: 'c3446e41-9eb0-4301-aeb4-356d0fdcf9af' })
          end
        end
      end

      describe 'remove_bg_status' do
        it 'checking the status background image removal file' do
          VCR.use_cassette('remove_bg_status') do
            uuid = 'c3446e41-9eb0-4301-aeb4-356d0fdcf9af'
            response = subject.remove_bg_status(uuid)
            expect(response.success).to(
              eq({ status: 'done', result: { file_id: 'bc37b996-916d-4ed7-b230-fa71a4290cb3' } })
            )
          end
        end
      end
    end
  end
end

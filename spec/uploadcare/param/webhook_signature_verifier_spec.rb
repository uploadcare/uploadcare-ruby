# frozen_string_literal: true

require 'spec_helper'
require 'param/simple_auth_header'

module Uploadcare
  RSpec.describe Param::WebhookSignatureVerifier do
    subject(:signature_valid?) { described_class.valid?(**params) }

    let(:webhook_body) do
      {
        payload_hash: '1844671900',
        data: {
          uuid: 'f08d7c8a-2971-42e0-ab01-780d9039b40b',
          image_info: {
            color_mode: 'RGB', format: 'JPEG', height: 168, width: 300, orientation: nil, dpi: nil,
            geo_location: nil, datetime_original: nil, sequence: false
          },
          video_info: nil,
          content_info: {
            mime: {
              mime: 'image/jpeg', type: 'image', subtype: 'jpeg'
            },
            video: nil,
            image: {
              color_mode: 'RGB', format: 'JPEG', height: 168, width: 300, orientation: nil, dpi: nil,
              geo_location: nil, datetime_original: nil, sequence: false
            }
          },
          mime_type: 'image/jpeg',
          original_filename: 'download.jpeg',
          size: 10_603,
          is_image: true,
          is_ready: true,
          datetime_removed: nil,
          datetime_stored: nil,
          datetime_uploaded: nil,
          original_file_url: 'https://ucarecdn.com/f08d7c8a-2971-42e0-ab01-780d9039b40b/download.jpeg',
          url: '',
          source: nil,
          variations: nil,
          rekognition_info: nil
        },
        hook: {
          id: 889_783,
          project_id: 123_681,
          target: 'https://6f48-188-232-175-230.ngrok.io/posts',
          event: 'file.uploaded',
          is_active: true,
          created_at: '2021-11-18T06:17:42.730459Z',
          updated_at: '2021-11-18T06:17:42.730459Z'
        },
        file: 'https://ucarecdn.com/f08d7c8a-2971-42e0-ab01-780d9039b40b/download.jpeg'
      }.to_json
    end

    let(:params) do
      {
        webhook_body: webhook_body,
        signing_secret: '12345X',
        x_uc_signature_header: 'v1=9b31c7dd83fdbf4a2e12b19d7f2b9d87d547672a325b9492457292db4f513c70'
      }
    end

    context 'when a signature is valid' do
      it 'returns true' do
        expect(signature_valid?).to be_truthy
      end
    end

    context 'when a signature is invalid' do
      let(:params) { super().merge(signing_secret: '12345') }

      it 'returns false' do
        expect(signature_valid?).to be_falsey
      end
    end
  end
end

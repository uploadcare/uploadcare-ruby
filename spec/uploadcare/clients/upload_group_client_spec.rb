# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  RSpec.describe UploadGroupClient do
    let(:config) { Uploadcare.configuration }
    let(:client) { described_class.new(config: config) }

    describe '#create_group' do
      let(:uuids) { %w[uuid-1 uuid-2 uuid-3] }
      let(:group_response) do
        {
          'id' => 'group-uuid~3',
          'datetime_created' => '2024-01-01T00:00:00Z',
          'datetime_stored' => nil,
          'files_count' => 3,
          'cdn_url' => 'https://ucarecdn.com/group-uuid~3/',
          'url' => 'https://api.uploadcare.com/groups/group-uuid~3/',
          'files' => uuids.map { |uuid| { 'uuid' => uuid } }
        }
      end

      before do
        stub_request(:post, 'https://upload.uploadcare.com/group/')
          .to_return(status: 200, body: group_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      context 'with valid uuids' do
        it 'creates a group successfully' do
          result = client.create_group(uuids: uuids)

          expect(result).to be_a(Uploadcare::Result)
          expect(result.success['id']).to eq('group-uuid~3')
          expect(result.success['files_count']).to eq(3)
        end

        it 'sends correct parameters' do
          client.create_group(uuids: uuids)

          expect(WebMock).to(have_requested(:post, 'https://upload.uploadcare.com/group/')
            .with { |req| req.body.include?('files%5B0%5D=uuid-1') && req.body.include?('pub_key') })
        end

        it 'includes public key' do
          client.create_group(uuids: uuids)

          expect(WebMock).to(have_requested(:post, 'https://upload.uploadcare.com/group/')
            .with { |req| req.body.include?("pub_key=#{config.public_key}") })
        end
      end

      context 'with file objects' do
        let(:file_objects) do
          uuids.map do |uuid|
            double('File', uuid: uuid, methods: [:uuid])
          end
        end

        it 'extracts uuids from file objects' do
          result = client.create_group(uuids: file_objects)

          expect(result).to be_a(Uploadcare::Result)
          expect(result.success['id']).to eq('group-uuid~3')
        end
      end

      context 'with signature and expire' do
        it 'includes signature parameter' do
          client.create_group(uuids: uuids, signature: 'test-signature', expire: 1_234_567_890)

          expect(WebMock).to(have_requested(:post, 'https://upload.uploadcare.com/group/')
            .with { |req| req.body.include?('signature=test-signature') && req.body.include?('expire=1234567890') })
        end
      end
    end

    describe '#info' do
      let(:group_id) { 'group-uuid~3' }
      let(:group_info_response) do
        {
          'id' => group_id,
          'datetime_created' => '2024-01-01T00:00:00Z',
          'files_count' => 3,
          'cdn_url' => 'https://ucarecdn.com/group-uuid~3/',
          'files' => [
            { 'uuid' => 'uuid-1', 'size' => 1000 },
            { 'uuid' => 'uuid-2', 'size' => 2000 },
            { 'uuid' => 'uuid-3', 'size' => 3000 }
          ]
        }
      end

      before do
        stub_request(:get, 'https://upload.uploadcare.com/group/info/')
          .with(query: hash_including('group_id' => group_id, 'pub_key' => config.public_key))
          .to_return(status: 200, body: group_info_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'retrieves group information' do
        result = client.info(group_id: group_id)

        expect(result).to be_a(Uploadcare::Result)
        expect(result.success['id']).to eq(group_id)
        expect(result.success['files_count']).to eq(3)
        expect(result.success['files']).to be_an(Array)
      end

      it 'sends correct parameters' do
        client.info(group_id: group_id)

        expect(WebMock).to have_requested(:get, 'https://upload.uploadcare.com/group/info/')
          .with(query: hash_including(
            'pub_key' => config.public_key,
            'group_id' => group_id
          ))
      end
    end

    describe '#group_body_hash' do
      let(:uuids) { %w[uuid-1 uuid-2] }

      it 'builds correct body hash' do
        result = client.send(:group_body_hash, uuids, {})

        expect(result).to have_key('pub_key')
        expect(result).to have_key('files[0]')
        expect(result).to have_key('files[1]')
        expect(result['files[0]']).to eq('uuid-1')
        expect(result['files[1]']).to eq('uuid-2')
      end

      it 'includes signature when provided' do
        result = client.send(:group_body_hash, uuids, signature: 'test-sig')

        expect(result).to have_key('signature')
        expect(result['signature']).to eq('test-sig')
      end

      it 'includes expire when provided' do
        result = client.send(:group_body_hash, uuids, expire: 123_456)

        expect(result).to have_key('expire')
        expect(result['expire']).to eq(123_456)
      end
    end

    describe '#file_params' do
      let(:file_ids) { %w[uuid-1 uuid-2 uuid-3] }

      it 'converts file IDs to indexed parameters' do
        result = client.send(:file_params, file_ids)

        expect(result).to eq({
                               'files[0]' => 'uuid-1',
                               'files[1]' => 'uuid-2',
                               'files[2]' => 'uuid-3'
                             })
      end

      it 'handles empty array' do
        result = client.send(:file_params, [])

        expect(result).to eq({})
      end

      it 'handles single file' do
        result = client.send(:file_params, ['uuid-1'])

        expect(result).to eq({ 'files[0]' => 'uuid-1' })
      end
    end

    describe '#parse_uuids' do
      it 'returns uuids as-is for strings' do
        uuids = %w[uuid-1 uuid-2]
        result = client.send(:parse_uuids, uuids)

        expect(result).to eq(uuids)
      end

      it 'extracts uuids from file objects' do
        file1 = double('File', uuid: 'uuid-1', methods: [:uuid])
        file2 = double('File', uuid: 'uuid-2', methods: [:uuid])

        result = client.send(:parse_uuids, [file1, file2])

        expect(result).to eq(%w[uuid-1 uuid-2])
      end

      it 'handles mixed array of strings and objects' do
        file1 = double('File', uuid: 'uuid-1', methods: [:uuid])

        result = client.send(:parse_uuids, [file1, 'uuid-2'])

        expect(result).to eq(%w[uuid-1 uuid-2])
      end
    end
  end
end

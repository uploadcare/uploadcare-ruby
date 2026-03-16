# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Api::Rest::DocumentConversions do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end
  let(:file_uuid) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }

  let(:rest) { Uploadcare::Api::Rest.new(config: config) }

  subject(:document_conversions) { described_class.new(rest: rest) }

  describe '#initialize' do
    it 'stores the rest client' do
      expect(document_conversions.rest).to eq(rest)
    end
  end

  describe '#info' do
    let(:encoded_uuid) { URI.encode_www_form_component(file_uuid) }

    before do
      stub_request(:get, "https://api.uploadcare.com/convert/document/#{encoded_uuid}/")
        .to_return(
          status: 200,
          body: {
            format: { name: 'pdf' },
            converted_groups: { 'pdf' => { uuid: 'group-uuid' } }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns document format info' do
      result = document_conversions.info(uuid: file_uuid)

      expect(result).to be_success
      expect(result.value!['format']['name']).to eq('pdf')
    end

    it 'URI-encodes the UUID in the path' do
      special_uuid = 'uuid/with spaces'
      encoded_special_uuid = URI.encode_www_form_component(special_uuid)

      stub = stub_request(:get, "https://api.uploadcare.com/convert/document/#{encoded_special_uuid}/")
             .to_return(
               status: 200,
               body: { format: { name: 'pdf' } }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      document_conversions.info(uuid: special_uuid)

      expect(stub).to have_been_requested
    end

    it 'returns a failure Result when file is not found' do
      stub_request(:get, 'https://api.uploadcare.com/convert/document/nonexistent/')
        .to_return(
          status: 404,
          body: { detail: 'Not found.' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = document_conversions.info(uuid: 'nonexistent')

      expect(result).to be_failure
    end
  end

  describe '#convert' do
    let(:conversion_path) { "#{file_uuid}/document/-/format/pdf/" }

    before do
      stub_request(:post, 'https://api.uploadcare.com/convert/document/')
        .to_return(
          status: 200,
          body: {
            result: [
              { original_source: file_uuid, token: 12_345, uuid: 'converted-uuid' }
            ],
            problems: {}
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'converts a document and returns the result' do
      result = document_conversions.convert(paths: [conversion_path])

      expect(result).to be_success
      expect(result.value!['result'].first['token']).to eq(12_345)
      expect(result.value!['problems']).to eq({})
    end

    it 'sends paths in the request body' do
      stub = stub_request(:post, 'https://api.uploadcare.com/convert/document/')
             .with(body: hash_including('paths' => [conversion_path]))
             .to_return(
               status: 200,
               body: { result: [], problems: {} }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      document_conversions.convert(paths: [conversion_path])

      expect(stub).to have_been_requested
    end

    it 'accepts store option' do
      stub = stub_request(:post, 'https://api.uploadcare.com/convert/document/')
             .with(body: hash_including('paths' => [conversion_path], 'store' => '1'))
             .to_return(
               status: 200,
               body: { result: [], problems: {} }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      document_conversions.convert(paths: [conversion_path], options: { store: true })

      expect(stub).to have_been_requested
    end

    it 'accepts save_in_group option' do
      stub = stub_request(:post, 'https://api.uploadcare.com/convert/document/')
             .with(body: hash_including('save_in_group' => '1'))
             .to_return(
               status: 200,
               body: { result: [], problems: {} }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      document_conversions.convert(paths: [conversion_path], options: { save_in_group: true })

      expect(stub).to have_been_requested
    end

    it 'normalizes boolean store parameter' do
      stub = stub_request(:post, 'https://api.uploadcare.com/convert/document/')
             .with(body: hash_including('store' => '0'))
             .to_return(
               status: 200,
               body: { result: [], problems: {} }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      document_conversions.convert(paths: [conversion_path], options: { store: false })

      expect(stub).to have_been_requested
    end

    it 'normalizes case-insensitive string booleans' do
      stub = stub_request(:post, 'https://api.uploadcare.com/convert/document/')
             .with(body: hash_including('store' => '0', 'save_in_group' => '1'))
             .to_return(
               status: 200,
               body: { result: [], problems: {} }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      document_conversions.convert(paths: [conversion_path], options: { store: 'False', save_in_group: 'TRUE' })

      expect(stub).to have_been_requested
    end

    it 'omits unsupported boolean-like values' do
      stub = stub_request(:post, 'https://api.uploadcare.com/convert/document/')
             .with do |request|
               body = JSON.parse(request.body)
               body['paths'] == [conversion_path] && !body.key?('store')
             end
             .to_return(
               status: 200,
               body: { result: [], problems: {} }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      document_conversions.convert(paths: [conversion_path], options: { store: 'no' })

      expect(stub).to have_been_requested
    end
  end

  describe '#status' do
    let(:token) { 12_345 }

    before do
      stub_request(:get, "https://api.uploadcare.com/convert/document/status/#{token}/")
        .to_return(
          status: 200,
          body: {
            status: 'finished',
            result: { uuid: 'converted-uuid' },
            error: nil
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns the conversion job status' do
      result = document_conversions.status(token: token)

      expect(result).to be_success
      expect(result.value!['status']).to eq('finished')
      expect(result.value!['result']['uuid']).to eq('converted-uuid')
    end

    it 'handles pending status' do
      stub_request(:get, "https://api.uploadcare.com/convert/document/status/#{token}/")
        .to_return(
          status: 200,
          body: { status: 'pending', result: nil, error: nil }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = document_conversions.status(token: token)

      expect(result).to be_success
      expect(result.value!['status']).to eq('pending')
    end
  end
end

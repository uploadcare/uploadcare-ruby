# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::FileClient do
  let(:client) { described_class.new }
  let(:rest_api_root) { Uploadcare.configuration.rest_api_root }

  describe '#list' do
    let(:path) { '/files/' }
    let(:params) { { 'limit' => 10, 'ordering' => '-datetime_uploaded' } }
    let(:full_url) { "#{rest_api_root}#{path}" }

    subject(:result) { client.list(params: params) }

    context 'when the request is successful' do
      let(:response_body) do
        {
          'next' => nil,
          'previous' => nil,
          'per_page' => 10,
          'results' => [
            {
              'uuid' => 'file_uuid_1',
              'original_filename' => 'file1.jpg',
              'size' => 12_345
            },
            {
              'uuid' => 'file_uuid_2',
              'original_filename' => 'file2.jpg',
              'size' => 67_890
            }
          ],
          'total' => 2
        }
      end

      before do
        stub_request(:get, full_url)
          .with(
            query: params
          )
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it { expect(result.success).to eq(response_body) }
    end

    context 'when the request returns an error' do
      before do
        stub_request(:get, full_url)
          .with(
            query: params
          )
          .to_return(
            status: 400,
            body: { 'detail' => 'Bad Request' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an InvalidRequestError' do
        expect(result.failure?).to be true
        expect(result.error).to be_a(Uploadcare::Exception::RequestError)
        expect(result.error.message).to eq('Bad Request')
      end
    end
  end

  describe '#store' do
    let(:uuid) { SecureRandom.uuid }
    let(:path) { "/files/#{uuid}/storage/" }
    let(:full_url) { "#{rest_api_root}#{path}" }

    subject(:result) { client.store(uuid: uuid) }

    context 'when the request is successful' do
      let(:response_body) do
        {
          datetime_removed: nil,
          datetime_stored: '2018-11-26T12:49:10.477888Z',
          datetime_uploaded: '2018-11-26T12:49:09.945335Z',
          variations: nil,
          is_image: true,
          is_ready: true,
          mime_type: 'image/jpeg',
          original_file_url: "https://ucarecdn.com/#{uuid}/file.jpg",
          original_filename: 'file.jpg',
          size: 642,
          url: "https://api.uploadcare.com/files/#{uuid}/",
          uuid: uuid
        }
      end
      before do
        stub_request(:put, full_url)
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end
      it { expect(result.success).to include('uuid' => uuid) }
      it { expect(result.success).to include('datetime_stored') }
    end

    context 'when the request returns an error' do
      before do
        stub_request(:put, full_url)
          .to_return(
            status: 400,
            body: { 'detail' => 'Bad Request' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an InvalidRequestError' do
        expect(result.failure?).to be true
        expect(result.error).to be_a(Uploadcare::Exception::RequestError)
        expect(result.error.message).to eq('Bad Request')
      end
    end
  end

  describe '#delete' do
    let(:uuid) { SecureRandom.uuid }
    let(:path) { "/files/#{uuid}/storage/" }
    let(:full_url) { "#{rest_api_root}#{path}" }
    let(:removed_date) { Time.now }

    subject(:result) { client.delete(uuid: uuid) }

    context 'when the request is successful' do
      let(:response_body) do
        {
          datetime_removed: removed_date,
          datetime_stored: nil,
          datetime_uploaded: '2018-11-26T12:49:09.945335Z',
          variations: nil,
          is_image: true,
          is_ready: true,
          mime_type: 'image/jpeg',
          original_file_url: "https://ucarecdn.com/#{uuid}/file.jpg",
          original_filename: 'file.jpg',
          size: 642,
          url: "https://api.uploadcare.com/files/#{uuid}/",
          uuid: uuid
        }
      end
      before do
        stub_request(:delete, full_url)
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end
      it { expect(result.success).to include('uuid' => uuid) }
      it { expect(result.success).to include('datetime_removed') }
    end

    context 'when the request returns an error' do
      before do
        stub_request(:delete, full_url)
          .to_return(
            status: 404,
            body: { 'detail' => 'Bad Request' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an InvalidRequest' do
        expect(result.failure?).to be true
        expect(result.error).to be_a(Uploadcare::Exception::RequestError)
        expect(result.error.message).to eq('Bad Request')
      end
    end
  end

  describe '#info' do
    let(:uuid) { SecureRandom.uuid }
    let(:path) { "/files/#{uuid}/" }
    let(:full_url) { "#{rest_api_root}#{path}" }

    subject(:result) { client.info(uuid: uuid) }

    context 'when the request is successful' do
      let(:response_body) do
        {
          datetime_removed: nil,
          datetime_stored: '2018-11-26T12:49:10.477888Z',
          datetime_uploaded: '2018-11-26T12:49:09.945335Z',
          variations: nil,
          is_image: true,
          is_ready: true,
          mime_type: 'image/jpeg',
          original_file_url: "https://ucarecdn.com/#{uuid}/file.jpg",
          original_filename: 'file.jpg',
          size: 642,
          url: "https://api.uploadcare.com/files/#{uuid}/",
          uuid: uuid
        }
      end
      before do
        stub_request(:get, full_url)
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end
      it { expect(result.success).to include('uuid' => uuid) }
      it { expect(result.success).to include('datetime_removed') }
    end

    context 'when the request returns an error' do
      before do
        stub_request(:get, full_url)
          .to_return(
            status: 404,
            body: { 'detail' => 'Bad Request' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an InvalidRequest' do
        expect(result.failure?).to be true
        expect(result.error).to be_a(Uploadcare::Exception::RequestError)
        expect(result.error.message).to eq('Bad Request')
      end
    end
  end

  describe '#batch_store' do
    let(:uuids) { [SecureRandom.uuid, SecureRandom.uuid] }
    let(:path) { '/files/storage/' }
    let(:full_url) { "#{rest_api_root}#{path}" }
    let(:file_data) { { 'uuid' => SecureRandom.uuid, 'original_filename' => 'file.jpg' } }

    subject(:result) { client.batch_store(uuids: uuids) }

    context 'when the request is successful' do
      let(:response_body) do
        {
          status: 200,
          result: [file_data],
          problems: [{ 'some-uuid': 'Missing in the project' }]
        }
      end
      before do
        stub_request(:put, full_url)
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end
      it { expect(result.success).to include('result') }
      it { expect(result.success).to include({ 'status' => 200 }) }
      it { expect(result.success).to include('problems') }
    end

    context 'when the request returns an error' do
      before do
        stub_request(:put, full_url)
          .to_return(
            status: 404,
            body: { 'detail' => 'Bad Request' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an InvalidRequest' do
        expect(result.failure?).to be true
        expect(result.error).to be_a(Uploadcare::Exception::RequestError)
        expect(result.error.message).to eq('Bad Request')
      end
    end
  end

  describe '#batch_delete' do
    let(:uuids) { [SecureRandom.uuid, SecureRandom.uuid] }
    let(:path) { '/files/storage/' }
    let(:full_url) { "#{rest_api_root}#{path}" }
    let(:file_data) { { 'uuid' => SecureRandom.uuid, 'original_filename' => 'file.jpg' } }

    subject(:result) { client.batch_delete(uuids: uuids) }

    context 'when the request is successful' do
      let(:response_body) do
        {
          status: 200,
          result: [file_data],
          problems: [{ 'some-uuid': 'Missing in the project' }]
        }
      end
      before do
        stub_request(:delete, full_url)
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end
      it { expect(result.success).to include('result') }
      it { expect(result.success).to include({ 'status' => 200 }) }
      it { expect(result.success).to include('problems') }
    end

    context 'when the request returns an error' do
      before do
        stub_request(:delete, full_url)
          .to_return(
            status: 404,
            body: { 'detail' => 'Bad Request' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an InvalidRequest' do
        expect(result.failure?).to be true
        expect(result.error).to be_a(Uploadcare::Exception::RequestError)
        expect(result.error.message).to eq('Bad Request')
      end
    end
  end

  describe '#local_copy' do
    let(:source) { SecureRandom.uuid }
    let(:path) { '/files/local_copy/' }
    let(:full_url) { "#{rest_api_root}#{path}" }

    subject(:result) { client.local_copy(source: source) }

    context 'when the request is successful' do
      let(:response_body) do
        {
          type: 'file',
          result: {
            datetime_removed: nil,
            datetime_stored: '2018-11-26T12:49:10.477888Z',
            datetime_uploaded: '2018-11-26T12:49:09.945335Z',
            variations: nil,
            is_image: true,
            is_ready: true,
            mime_type: 'image/jpeg',
            original_file_url: "https://ucarecdn.com/#{source}/file.jpg",
            original_filename: 'file.jpg',
            size: 642,
            url: "https://api.uploadcare.com/files/#{source}/",
            uuid: source
          }
        }
      end
      before do
        stub_request(:post, full_url)
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end
      it { expect(result.success).to include('result') }
      it { expect(result.success).to include({ 'type' => 'file' }) }
      it { expect(result.success['result']['uuid']).to eq(source) }
    end

    context 'when the request returns an error' do
      before do
        stub_request(:post, full_url)
          .to_return(
            status: 400,
            body: { 'detail' => 'Bad Request' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an InvalidRequest' do
        result = client.local_copy(source: source)
        expect(result.failure?).to be true
        expect(result.error).to be_a(Uploadcare::Exception::RequestError)
        expect(result.error.message).to eq('Bad Request')
      end
    end
  end
  describe '#remote_copy' do
    let(:source) { SecureRandom.uuid }
    let(:target) { 's3://mybucket/copied_file.jpg' }
    let(:options) { { make_public: true, pattern: '${default}' } }
    let(:path) { '/files/remote_copy/' }
    let(:full_url) { "#{rest_api_root}#{path}" }

    subject(:result) { client.remote_copy(source: source, target: target, options: options) }

    context 'when the request is successful' do
      let(:response_body) { { type: 'url', result: 's3_url' } }
      before do
        stub_request(:post, full_url)
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end
      it { expect(result.success).to include({ 'type' => 'url' }) }
      it { expect(result.success['result']).to be_a(String) }
    end

    context 'when the request returns an error' do
      before do
        stub_request(:post, full_url)
          .to_return(
            status: 400,
            body: { 'detail' => 'Bad Request' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an InvalidRequest' do
        expect(result.failure?).to be true
        expect(result.error).to be_a(Uploadcare::Exception::RequestError)
        expect(result.error.message).to eq('Bad Request')
      end
    end
  end
end

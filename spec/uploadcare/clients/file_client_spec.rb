# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::FileClient do
  let(:client) { described_class.new }
  let(:rest_api_root) { Uploadcare.configuration.rest_api_root }

  describe '#list' do
    let(:path) { '/files/' }
    let(:params) { { 'limit' => 10, 'ordering' => '-datetime_uploaded' } }
    let(:full_url) { "#{rest_api_root}#{path}" }

    subject { client.list(params) }

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

      it { is_expected.to eq(response_body) }
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
        expect { client.list(params) }.to raise_error(Uploadcare::BadRequestError, "Bad Request")
      end
    end
  end

  describe '#store' do
    let(:uuid) { SecureRandom.uuid }
    let(:path) { "/files/#{uuid}/storage/" }
    let(:full_url) { "#{rest_api_root}#{path}" }

    subject { client.store(uuid) }

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
      it { is_expected.to include('uuid' => uuid) }
      it { is_expected.to include('datetime_stored') }
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
        expect { client.store(uuid) }.to raise_error(Uploadcare::BadRequestError, "Bad Request")
      end
    end
  end

  describe '#delete' do
    let(:uuid) { SecureRandom.uuid }
    let(:path) { "/files/#{uuid}/storage/" }
    let(:full_url) { "#{rest_api_root}#{path}" }
    let(:removed_date) { Time.now }

    subject { client.delete(uuid) }

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
      it { is_expected.to include('uuid' => uuid) }
      it { is_expected.to include('datetime_removed') }
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
        expect { client.delete(uuid) }.to raise_error(Uploadcare::BadRequestError, "Bad Request")
      end
    end
  end

  describe '#info' do
    let(:uuid) { SecureRandom.uuid }
    let(:path) { "/files/#{uuid}/" }
    let(:full_url) { "#{rest_api_root}#{path}" }

    subject { client.info(uuid) }

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
      it { is_expected.to include('uuid' => uuid) }
      it { is_expected.to include('datetime_removed') }
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
        expect { client.info(uuid) }.to raise_error(Uploadcare::BadRequestError, "Bad Request")
      end
    end
  end

  describe '#batch_store' do
    let(:uuids) { [SecureRandom.uuid, SecureRandom.uuid] }
    let(:path) { '/files/storage/' }
    let(:full_url) { "#{rest_api_root}#{path}" }
    let(:file_data) { { 'uuid' => SecureRandom.uuid, 'original_filename' => 'file.jpg' } }

    subject { client.batch_store(uuids) }

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
      it { is_expected.to include('result') }
      it { is_expected.to include({ 'status' => 200 }) }
      it { is_expected.to include('problems') }
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
        expect { client.batch_store(uuids) }.to raise_error(Uploadcare::BadRequestError, "Bad Request")
      end
    end
  end

  describe '#batch_delete' do
    let(:uuids) { [SecureRandom.uuid, SecureRandom.uuid] }
    let(:path) { '/files/storage/' }
    let(:full_url) { "#{rest_api_root}#{path}" }
    let(:file_data) { { 'uuid' => SecureRandom.uuid, 'original_filename' => 'file.jpg' } }

    subject { client.batch_delete(uuids) }

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
      it { is_expected.to include('result') }
      it { is_expected.to include({ 'status' => 200 }) }
      it { is_expected.to include('problems') }
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
        expect { client.batch_delete(uuids) }.to raise_error(Uploadcare::BadRequestError, "Bad Request")
      end
    end
  end

  describe '#local_copy' do
    let(:source) { SecureRandom.uuid }
    let(:path) { '/files/local_copy/' }
    let(:full_url) { "#{rest_api_root}#{path}" }

    subject { client.local_copy(source) }

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
      it { is_expected.to include('result') }
      it { is_expected.to include({ 'type' => 'file' }) }
      it { expect(subject['result']['uuid']).to eq(source) }
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
        expect { client.local_copy(source) }.to raise_error(Uploadcare::BadRequestError, "Bad Request")
      end
    end
  end
  describe '#remote_copy' do
    let(:source) { SecureRandom.uuid }
    let(:target) { 's3://mybucket/copied_file.jpg' }
    let(:options) { { make_public: true, pattern: '${default}' } }
    let(:path) { '/files/remote_copy/' }
    let(:full_url) { "#{rest_api_root}#{path}" }

    subject { client.remote_copy(source, target, options) }

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
      it { is_expected.to include({ 'type' => 'url' }) }
      it { expect(subject['result']).to be_a(String) }
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
        expect { client.remote_copy(source, target, options) }.to raise_error(Uploadcare::BadRequestError, "Bad Request")
      end
    end
  end
end

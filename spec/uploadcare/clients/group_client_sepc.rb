# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::GroupClient do
  let(:client) { described_class.new }
  let(:rest_api_root) { Uploadcare.configuration.rest_api_root }

  describe '#list' do
    let(:path) { '/groups/' }
    let(:params) { { 'limit' => 10, 'ordering' => '-datetime_created' } }
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
              'id' => 'group_uuid_1~2',
              'datetime_created' => '2023-11-01T12:49:10.477888Z',
              'files_count' => 2,
              'cdn_url' => 'https://ucarecdn.com/group_uuid_1~2/',
              'url' => "#{rest_api_root}groups/group_uuid_1~2/"
            },
            {
              'id' => 'group_uuid_2~3',
              'datetime_created' => '2023-11-02T12:49:10.477888Z',
              'files_count' => 3,
              'cdn_url' => 'https://ucarecdn.com/group_uuid_2~3/',
              'url' => "#{rest_api_root}groups/group_uuid_2~3/"
            }
          ],
          'total' => 2
        }
      end

      before do
        stub_request(:get, full_url)
          .with(query: params)
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it { is_expected.to eq(response_body) }
    end

    context 'when the request returns an error' do
      before do
        stub_request(:get, full_url)
          .with(query: params)
          .to_return(status: 400, body: { 'detail' => 'Bad Request' }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises an InvalidRequestError' do
        expect { client.list(params) }.to raise_error(Uploadcare::InvalidRequestError, 'Bad Request')
      end
    end
  end

  describe '#info' do
    let(:uuid) { 'group_uuid_1~2' }
    let(:path) { "/groups/#{uuid}/" }
    let(:full_url) { "#{rest_api_root}#{path}" }

    subject { client.info(uuid) }

    context 'when the request is successful' do
      let(:response_body) do
        {
          'id' => uuid,
          'datetime_created' => '2023-11-01T12:49:10.477888Z',
          'files_count' => 2,
          'cdn_url' => "https://ucarecdn.com/#{uuid}/",
          'url' => "#{rest_api_root}groups/#{uuid}/",
          'files' => [
            {
              'uuid' => 'file_uuid_1',
              'datetime_uploaded' => '2023-11-01T12:49:09.945335Z',
              'is_image' => true,
              'mime_type' => 'image/jpeg',
              'original_filename' => 'file1.jpg',
              'size' => 12_345
            }
          ]
        }
      end

      before do
        stub_request(:get, full_url)
          .to_return(status: 200, body: response_body.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it { is_expected.to eq(response_body) }
    end

    context 'when the request returns an error' do
      before do
        stub_request(:get, full_url)
          .to_return(status: 404, body: { 'detail' => 'Not Found' }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises a NotFoundError' do
        expect { client.info(uuid) }.to raise_error(Uploadcare::NotFoundError, 'Not Found')
      end
    end
  end
end

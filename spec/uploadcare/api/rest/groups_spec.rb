# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Api::Rest::Groups do
  let(:config) do
    Uploadcare::Configuration.new(
      public_key: 'demopublickey',
      secret_key: 'demosecretkey',
      auth_type: 'Uploadcare.Simple'
    )
  end
  let(:group_uuid) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890~3' }

  let(:rest) { Uploadcare::Api::Rest.new(config: config) }

  subject(:groups) { described_class.new(rest: rest) }

  describe '#initialize' do
    it 'stores the rest client' do
      expect(groups.rest).to eq(rest)
    end
  end

  describe '#list' do
    before do
      stub_request(:get, 'https://api.uploadcare.com/groups/')
        .to_return(
          status: 200,
          body: {
            next: nil,
            previous: nil,
            total: 1,
            per_page: 100,
            results: [
              { id: group_uuid, files_count: 3, datetime_created: '2024-01-01T00:00:00Z' }
            ]
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns a paginated list of groups' do
      result = groups.list

      expect(result).to be_success
      expect(result.value!['results'].length).to eq(1)
      expect(result.value!['total']).to eq(1)
    end

    it 'passes query params' do
      stub_request(:get, 'https://api.uploadcare.com/groups/')
        .with(query: { limit: '5' })
        .to_return(
          status: 200,
          body: { results: [], total: 0 }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = groups.list(params: { limit: '5' })

      expect(result).to be_success
    end
  end

  describe '#info' do
    before do
      stub_request(:get, %r{https://api\.uploadcare\.com/groups/.*})
        .to_return(
          status: 200,
          body: {
            id: group_uuid,
            files_count: 3,
            files: [
              { uuid: 'file-1' },
              { uuid: 'file-2' },
              { uuid: 'file-3' }
            ]
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns group details for the given UUID' do
      result = groups.info(uuid: group_uuid)

      expect(result).to be_success
      expect(result.value!['id']).to eq(group_uuid)
      expect(result.value!['files_count']).to eq(3)
    end

    it 'URI-encodes the tilde character in the group UUID' do
      stub = stub_request(:get, 'https://api.uploadcare.com/groups/a1b2c3d4-e5f6-7890-abcd-ef1234567890~3/')
             .to_return(
               status: 200,
               body: { id: group_uuid }.to_json,
               headers: { 'Content-Type' => 'application/json' }
             )

      groups.info(uuid: group_uuid)

      expect(stub).to have_been_requested
    end
  end

  describe '#delete' do
    before do
      stub_request(:delete, %r{https://api\.uploadcare\.com/groups/.*})
        .to_return(
          status: 200,
          body: ''.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'deletes a group and returns a Result' do
      result = groups.delete(uuid: group_uuid)

      expect(result).to be_a(Uploadcare::Result)
      expect(result).to be_success
    end
  end
end

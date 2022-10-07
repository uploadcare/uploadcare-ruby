# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Client
    RSpec.describe GroupClient do
      subject { GroupClient.new }
      let!(:uuids) { %w[8ca6e9fa-c6dd-4027-a0fc-b620611f7023 b8a11440-6fcc-4285-a24d-cc8c60259fec] }

      describe 'create' do
        it 'creates a group' do
          VCR.use_cassette('upload_create_group') do
            response = subject.create(uuids)
            response_body = response.success
            expect(response_body[:files_count]).to eq 2
            %i[id datetime_created datetime_stored files_count cdn_url url files].each do |key|
              expect(response_body).to have_key key
            end
            expect(response_body[:url]).to include 'https://api.uploadcare.com/groups'
          end
        end
        context 'array of Entity::Files' do
          it 'creates a group' do
            VCR.use_cassette('upload_create_group_from_files') do
              files = uuids.map { |uuid| Uploadcare::Entity::File.new(uuid: uuid) }
              response = subject.create(files)
              response_body = response.success
              expect(response_body[:files_count]).to eq 2
            end
          end
        end
      end

      describe 'info' do
        it 'returns group info' do
          VCR.use_cassette('upload_group_info') do
            response = subject.info('bbc75785-9016-4656-9c6e-64a76b45b0b8~2')
            response_body = response.success
            %i[id datetime_created datetime_stored files_count cdn_url url files].each do |key|
              expect(response_body).to have_key key
            end
          end
        end
      end
    end
  end
end

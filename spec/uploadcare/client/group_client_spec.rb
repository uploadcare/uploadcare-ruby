# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Client
    RSpec.describe GroupClient do
      subject { GroupClient.new }
      let!(:uuids) { ['e9a9f291-cc52-4388-bf65-9feec1c75ff9', 'c724feac-86f7-447c-b2d6-b0ced220173d'] }

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
      end

      describe 'info' do
        it 'returns group info' do
          VCR.use_cassette('upload_group_info') do
            response = subject.info('69bafb24-5bfc-45d8-ba85-b3ea88e8eb17~1')
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

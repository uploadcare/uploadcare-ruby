# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Client
    RSpec.describe RestGroupClient do
      subject { RestGroupClient.new }

      describe 'store' do
        it 'stores all files in a group' do
          VCR.use_cassette('rest_store_group') do
            group_id = '47e6cf32-e5a8-4ff4-b48f-14d7304b42dd~2'
            response = subject.store(group_id)
            expect(response.success).to be_truthy
          end
        end
      end

      describe 'info' do
        it 'gets a file group by its ID.' do
          VCR.use_cassette('rest_info_group') do
            group_id = '47e6cf32-e5a8-4ff4-b48f-14d7304b42dd~2'
            response = subject.info(group_id)
            response_body = response.success
            expect(response_body[:files_count]).to eq(2)
            %i[id datetime_created files_count cdn_url url files].each { |key| expect(response_body).to have_key(key) }
          end
        end
      end

      describe 'list' do
        it 'returns paginated list of groups' do
          VCR.use_cassette('rest_list_groups') do
            response = subject.list
            response_value = response.value!
            expect(response_value[:results]).to be_a_kind_of(Array)
            expect(response_value[:total]).to be_a_kind_of(Integer)
          end
        end

        it 'accepts params' do
          VCR.use_cassette('rest_list_groups_limited') do
            response = subject.list(limit: 2)
            response_value = response.value!
            expect(response_value[:per_page]).to eq 2
          end
        end
      end

      describe 'delete' do
        it 'deletes a file group' do
          VCR.use_cassette('upload_group_delete') do
            response = subject.delete('bbc75785-9016-4656-9c6e-64a76b45b0b8~2')
            expect(response.value!).to be_nil
            expect(response.success?).to be_truthy
          end
        end
      end
    end
  end
end

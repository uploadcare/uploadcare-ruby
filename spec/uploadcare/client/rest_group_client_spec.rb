# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Client
    RSpec.describe RestGroupClient do
      subject { RestGroupClient.new }

      describe 'store' do
        it 'stores all files in a group' do
          VCR.use_cassette('rest_store_group') do
            group_id = 'fc194fec-5793-4403-a593-686af4be412e~2'
            response = subject.store(group_id)
            response_value = response.value!
            expect(response_value[:datetime_stored]).not_to be_empty
            expect(response_value[:id]).to eq(group_id)
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
        it "delete a file's group" do
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

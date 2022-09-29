# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Entity
    RSpec.describe Group do
      subject { Group }
      it 'responds to expected methods' do
        %i[create info store delete].each do |method|
          expect(subject).to respond_to(method)
        end
      end

      context 'info' do
        before do
          VCR.use_cassette('upload_group_info') do
            @group = subject.info('bbc75785-9016-4656-9c6e-64a76b45b0b8~2')
          end
        end

        it 'represents a file group' do
          file_fields = %i[id datetime_created datetime_stored files_count cdn_url url files]
          file_fields.each do |method|
            expect(@group).to respond_to(method)
          end
        end

        it 'has files' do
          expect(@group.files).not_to be_empty
          expect(@group.files.first).to be_a_kind_of(Uploadcare::Entity::File)
        end
      end

      describe 'id' do
        it 'returns id, even if only cdn_url is defined' do
          group = Group.new(cdn_url: 'https://ucarecdn.com/bbc75785-9016-4656-9c6e-64a76b45b0b8~2')
          expect(group.id).to eq 'bbc75785-9016-4656-9c6e-64a76b45b0b8~2'
        end
      end

      describe 'load' do
        it 'performs load request' do
          VCR.use_cassette('upload_group_info') do
            cdn_url = 'https://ucarecdn.com/bbc75785-9016-4656-9c6e-64a76b45b0b8~2'
            group = Group.new(cdn_url: cdn_url)
            group.load
            expect(group.files_count).not_to be_nil
          end
        end
      end

      describe 'delete' do
        it "deletes a file's group" do
          VCR.use_cassette('upload_group_delete') do
            response = subject.delete('bbc75785-9016-4656-9c6e-64a76b45b0b8~2')
            expect(response).to eq('200 OK')
          end
        end

        it 'raises error for nonexistent file' do
          VCR.use_cassette('group_delete_nonexistent_uuid') do
            uuid = 'nonexistent'
            expect { subject.delete(uuid) }.to raise_error(RequestError)
          end
        end
      end
    end
  end
end

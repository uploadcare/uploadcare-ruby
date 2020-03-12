# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Entity
    RSpec.describe Group do
      subject { Group }
      it 'responds to expected methods' do
        %i[create info store].each do |method|
          expect(subject).to respond_to(method)
        end
      end

      context 'info' do
        before do
          VCR.use_cassette('upload_group_info') do
            @group = subject.info('69bafb24-5bfc-45d8-ba85-b3ea88e8eb17~1')
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
          group = Group.new(cdn_url: 'https://ucarecdn.com/69bafb24-5bfc-45d8-ba85-b3ea88e8eb17~1')
          expect(group.id).to eq '69bafb24-5bfc-45d8-ba85-b3ea88e8eb17~1'
        end
      end

      describe 'load' do
        it 'performs load request' do
          VCR.use_cassette('upload_group_info') do
            cdn_url = 'https://ucarecdn.com/69bafb24-5bfc-45d8-ba85-b3ea88e8eb17~1'
            group = Group.new(cdn_url: cdn_url)
            group.load
            expect(group.files_count).not_to be_nil
          end
        end
      end
    end
  end
end

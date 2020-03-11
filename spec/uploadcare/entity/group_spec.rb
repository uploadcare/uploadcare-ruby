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
    end
  end
end

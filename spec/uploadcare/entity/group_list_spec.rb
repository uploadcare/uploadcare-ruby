# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Entity
    RSpec.describe GroupList do
      subject { GroupList }
      it 'responds to expected methods' do
        %i[list].each do |method|
          expect(subject).to respond_to(method)
        end
      end

      context 'list' do
        before do
          VCR.use_cassette('rest_list_groups_limited') do
            @groups = subject.list(limit: 2)
          end
        end

        it 'represents a file group' do
          expect(@groups.groups[0]).to be_a_kind_of(Group)
        end
      end
    end
  end
end

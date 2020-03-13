# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Entity
    module Decorator
      RSpec.describe Paginator do
        describe 'meta' do
          it 'accepts arguments' do
            VCR.use_cassette('rest_file_list_params') do
              fl_with_params = FileList.file_list(limit: 2, ordering: 'size')
              expect(fl_with_params.meta.per_page).to eq 2
            end
          end
        end

        describe 'next_page' do
          it 'loads a next page as separate object' do
            VCR.use_cassette('rest_file_list_pages') do
              fl_with_params = FileList.file_list(limit: 2, ordering: 'size')
              next_page = fl_with_params.next_page
              expect(next_page.previous).not_to be_nil
              expect(fl_with_params).not_to eq(next_page)
            end
          end
        end

        describe 'previous_page' do
          it 'loads a previous page as separate object' do
            VCR.use_cassette('rest_file_list_previous_page') do
              fl_with_params = FileList.file_list(limit: 2, ordering: 'size')
              next_page = fl_with_params.next_page
              previous_page = next_page.previous_page
              expect(previous_page.next).not_to be_nil
              expect(fl_with_params).to eq(previous_page)
            end
          end
        end

        describe 'load' do
          it 'loads all objects' do
            VCR.use_cassette('rest_file_list_load') do
              fl_with_params = FileList.file_list(limit: 2, ordering: 'size')
              fl_with_params.load
              expect(fl_with_params.results.length).to eq fl_with_params.total
            end
          end
        end

        describe 'each' do
          it 'iterates each file in list' do
            VCR.use_cassette('rest_file_list_each') do
              fl_with_params = FileList.file_list(limit: 2)
              entities = []
              fl_with_params.each do |file|
                entities << file
              end
              expect(entities.length).to eq fl_with_params.total
            end
          end
        end
      end
    end
  end
end

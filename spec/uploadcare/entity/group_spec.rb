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
        it 'deletes a file group' do
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

      describe 'cdn_url' do
        let(:test_group_id) { 'bbc75785-9016-4656-9c6e-64a76b45b0b8~2' }
        let(:group) { Group.new(id: test_group_id) }

        before do
          # Reset any memoized config values
          allow(Uploadcare.config).to receive(:cdn_base).and_call_original
        end

        it 'generates CDN URL using cdn_base config' do
          allow(Uploadcare.config).to receive(:cdn_base).and_return(-> { 'https://example.ucarecdn.com' })

          result = group.cdn_url
          expect(result).to eq("https://example.ucarecdn.com#{test_group_id}/")
        end

        it 'handles different CDN base configurations' do
          test_cases = [
            { base: 'https://custom.cdn.com', expected: "https://custom.cdn.com#{test_group_id}/" },
            { base: 'https://subdomain.ucarecdn.com', expected: "https://subdomain.ucarecdn.com#{test_group_id}/" },
            { base: 'https://cdn.example.org', expected: "https://cdn.example.org#{test_group_id}/" }
          ]

          test_cases.each do |test_case|
            allow(Uploadcare.config).to receive(:cdn_base).and_return(-> { test_case[:base] })
            expect(group.cdn_url).to eq(test_case[:expected])
          end
        end

        it 'works with group initialized from cdn_url' do
          cdn_url_group = Group.new(cdn_url: "https://ucarecdn.com/#{test_group_id}/")
          allow(Uploadcare.config).to receive(:cdn_base).and_return(-> { 'https://test.cdn.com' })

          result = cdn_url_group.cdn_url
          expect(result).to eq("https://test.cdn.com#{test_group_id}/")
        end

        it 'calls cdn_base each time for dynamic config updates' do
          allow(Uploadcare.config).to receive(:cdn_base).and_return(-> { 'https://first.cdn.com' })
          first_call = group.cdn_url

          allow(Uploadcare.config).to receive(:cdn_base).and_return(-> { 'https://second.cdn.com' })
          second_call = group.cdn_url

          expect(first_call).to eq("https://first.cdn.com#{test_group_id}/")
          expect(second_call).to eq("https://second.cdn.com#{test_group_id}/")
        end

        it 'handles CDN base with trailing slashes correctly' do
          test_cases = [
            { base: 'https://cdn.com/', expected: "https://cdn.com/#{test_group_id}/" },
            { base: 'https://cdn.com', expected: "https://cdn.com#{test_group_id}/" }
          ]

          test_cases.each do |test_case|
            allow(Uploadcare.config).to receive(:cdn_base).and_return(-> { test_case[:base] })
            expect(group.cdn_url).to eq(test_case[:expected])
          end
        end

        it 'includes cdn_url in entity attributes' do
          expect(Group.new({})).to respond_to(:cdn_url)
        end

        it 'works with subdomains when enabled' do
          allow(Uploadcare.config).to receive(:use_subdomains).and_return(true)
          allow(Uploadcare.config).to receive(:public_key).and_return('test_public_key')
          allow(Uploadcare.config).to receive(:cdn_base).and_return(-> { 'https://abc123def.ucarecdn.com' })

          result = group.cdn_url
          expect(result).to eq("https://abc123def.ucarecdn.com#{test_group_id}/")
        end

        it 'handles custom CNAME domains' do
          allow(Uploadcare.config).to receive(:cdn_base).and_return(-> { 'https://my-custom-domain.com' })

          result = group.cdn_url
          expect(result).to eq("https://my-custom-domain.com#{test_group_id}/")
        end

        context 'integration with real config' do
          it 'generates valid CDN URL with default config' do
            # Don't mock cdn_base to test real integration
            result = group.cdn_url

            expect(result).to be_a(String)
            expect(result).to include(test_group_id)
            expect(result).to end_with('/')
            expect(result).to match(%r{\Ahttps?://})
          end
        end
      end

      describe 'file_cdn_urls' do
        let(:test_group_id) { 'bbc75785-9016-4656-9c6e-64a76b45b0b8~2' }
        let(:group) { Group.new(id: test_group_id) }

        before do
          allow(Uploadcare.config).to receive(:cdn_base).and_return(-> { 'https://ucarecdn.com/' })
        end

        it 'includes file_cdn_urls in entity attributes' do
          expect(Group.new({})).to respond_to(:file_cdn_urls)
        end

        it 'returns empty array for group with no files' do
          files_collection = double('files_collection', count: 0)
          allow(group).to receive(:files).and_return(files_collection)

          result = group.file_cdn_urls
          expect(result).to eq([])
        end

        it 'generates CDN URLs using group CDN URL and file indices' do
          files_collection = double('files_collection', count: 3)
          allow(group).to receive(:files).and_return(files_collection)

          result = group.file_cdn_urls

          expect(result).to be_an(Array)
          expect(result.length).to eq(3)
          expect(result[0]).to eq("https://ucarecdn.com/#{test_group_id}/nth/0/")
          expect(result[1]).to eq("https://ucarecdn.com/#{test_group_id}/nth/1/")
          expect(result[2]).to eq("https://ucarecdn.com/#{test_group_id}/nth/2/")
        end

        it 'uses group cdn_url method for base URL' do
          files_collection = double('files_collection', count: 2)
          allow(group).to receive(:files).and_return(files_collection)
          allow(group).to receive(:cdn_url).and_return('https://custom.cdn.com/group123/')

          result = group.file_cdn_urls

          expect(result).to eq([
                                 'https://custom.cdn.com/group123/nth/0/',
                                 'https://custom.cdn.com/group123/nth/1/'
                               ])
        end

        it 'handles single file' do
          files_collection = double('files_collection', count: 1)
          allow(group).to receive(:files).and_return(files_collection)

          result = group.file_cdn_urls

          expect(result).to eq(["https://ucarecdn.com/#{test_group_id}/nth/0/"])
        end

        it 'works with different CDN base configurations' do
          allow(Uploadcare.config).to receive(:cdn_base).and_return(-> { 'https://subdomain.ucarecdn.com/' })
          files_collection = double('files_collection', count: 2)
          allow(group).to receive(:files).and_return(files_collection)

          result = group.file_cdn_urls

          expect(result).to eq([
                                 "https://subdomain.ucarecdn.com/#{test_group_id}/nth/0/",
                                 "https://subdomain.ucarecdn.com/#{test_group_id}/nth/1/"
                               ])
        end

        it 'reflects dynamic CDN configuration changes' do
          files_collection = double('files_collection', count: 1)
          allow(group).to receive(:files).and_return(files_collection)

          allow(Uploadcare.config).to receive(:cdn_base).and_return(-> { 'https://first.cdn.com/' })
          first_result = group.file_cdn_urls

          allow(Uploadcare.config).to receive(:cdn_base).and_return(-> { 'https://second.cdn.com/' })
          second_result = group.file_cdn_urls

          expect(first_result).to eq(["https://first.cdn.com/#{test_group_id}/nth/0/"])
          expect(second_result).to eq(["https://second.cdn.com/#{test_group_id}/nth/0/"])
        end

        it 'generates URLs with correct index sequence' do
          files_collection = double('files_collection', count: 5)
          allow(group).to receive(:files).and_return(files_collection)

          result = group.file_cdn_urls

          expect(result.length).to eq(5)
          (0...5).each do |i|
            expect(result[i]).to eq("https://ucarecdn.com/#{test_group_id}/nth/#{i}/")
          end
        end

        context 'integration with real File entities' do
          it 'works with actual File objects and VCR' do
            VCR.use_cassette('upload_group_info') do
              group = Group.info('bbc75785-9016-4656-9c6e-64a76b45b0b8~2')

              urls = group.file_cdn_urls
              expect(urls).to be_an(Array)

              # Each URL should follow the nth pattern
              urls.each_with_index do |url, index|
                expect(url).to be_a(String)
                expect(url).to match(%r{\Ahttps?://})
                expect(url).to end_with("/nth/#{index}/")
                expect(url).to include(group.id)
              end
            end
          end
        end

        context 'performance considerations' do
          it 'efficiently processes large number of files' do
            files_collection = double('files_collection', count: 100)
            allow(group).to receive(:files).and_return(files_collection)

            start_time = Time.now
            result = group.file_cdn_urls
            end_time = Time.now

            expect(result.length).to eq(100)
            expect(end_time - start_time).to be < 0.1 # Should complete very quickly

            # Verify the pattern is correct for the last few
            expect(result[99]).to eq("https://ucarecdn.com/#{test_group_id}/nth/99/")
            expect(result[0]).to eq("https://ucarecdn.com/#{test_group_id}/nth/0/")
          end
        end

        context 'error handling' do
          it 'handles zero files gracefully' do
            files_collection = double('files_collection', count: 0)
            allow(group).to receive(:files).and_return(files_collection)

            result = group.file_cdn_urls
            expect(result).to eq([])
          end

          it 'handles nil files collection' do
            allow(group).to receive(:files).and_return(nil)

            expect { group.file_cdn_urls }.to raise_error(NoMethodError)
          end
        end
      end
    end
  end
end

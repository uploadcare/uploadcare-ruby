# frozen_string_literal: true

require 'spec_helper'

module Uploadcare
  module Client
    RSpec.describe WebhookClient do
      subject { WebhookClient.new }

      describe 'create' do
        shared_examples 'creating a webhook' do
          it 'creates a webhook' do
            VCR.use_cassette('rest_webhook_create') do
              response = subject.create(params)
              response_value = response.value!

              expect(response_value[:id]).not_to be nil
            end
          end

          it 'sends the :post with params' do
            VCR.use_cassette('rest_webhook_create') do
              expect_any_instance_of(described_class).to receive(:post).with(
                uri: '/webhooks/',
                content: expected_params.to_json
              )
              subject.create(params)
            end
          end
        end

        let(:params) { { target_url: 'http://ohmyz.sh', event: 'file.uploaded' } }

        context 'when a new webhook is enabled' do
          let(:is_active) { true }
          let(:expected_params) { params }

          context 'and when sending "true"' do
            it_behaves_like 'creating a webhook' do
              let(:params) { super().merge(is_active: true) }
            end
          end

          context 'and when sending "nil"' do
            it_behaves_like 'creating a webhook' do
              let(:expected_params) { params.merge(is_active: true) }
              let(:params) { super().merge(is_active: nil) }
            end
          end

          context 'and when not sending the param' do
            let(:expected_params) { params.merge(is_active: true) }
            it_behaves_like 'creating a webhook'
          end

          context 'and when sending a signing secret' do
            let(:params) do
              super().merge(is_active: true, signing_secret: '1234')
            end

            it 'sends the :post with params' do
              VCR.use_cassette('rest_webhook_create') do
                expect_any_instance_of(described_class).to receive(:post).with(
                  uri: '/webhooks/',
                  content: params.to_json
                )
                subject.create(params)
              end
            end
          end
        end

        context 'when a new webhook is disabled' do
          let(:is_active) { false }
          let(:expected_params) { params }

          context 'and when sending "false"' do
            it_behaves_like 'creating a webhook' do
              let(:params) { super().merge(is_active: false) }
            end
          end
        end
      end

      describe 'list' do
        it 'lists an array of webhooks' do
          VCR.use_cassette('rest_webhook_list') do
            response = subject.list
            response_value = response.value!
            expect(response_value).to be_a_kind_of(Array)
          end
        end
      end

      describe 'delete' do
        it 'destroys a webhook' do
          VCR.use_cassette('rest_webhook_destroy') do
            response = subject.delete('http://example.com')
            response_value = response.value!
            expect(response_value).to be_nil
            expect(response.success?).to be true
          end
        end
      end

      describe 'update' do
        it 'updates a webhook' do
          VCR.use_cassette('rest_webhook_update') do
            sub_id = 887_447
            target_url = 'https://github.com'
            is_active = false
            sign_secret = '1234'
            response = subject.update(sub_id, target_url: target_url, is_active: is_active, signing_secret: sign_secret)
            response_value = response.value!
            expect(response_value[:id]).to eq(sub_id)
            expect(response_value[:target_url]).to eq(target_url)
            expect(response_value[:is_active]).to eq(is_active)
          end
        end
      end
    end
  end
end

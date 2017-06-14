require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Api do
  subject(:api) { Uploadcare::Api.new(CONFIG) }

  it "should initialize api" do
    is_expected.to be_an_instance_of(Uploadcare::Api)
  end

  it 'should respond to request methods' do
    is_expected.to respond_to :request
    is_expected.to respond_to :get
    is_expected.to respond_to :post
    is_expected.to respond_to :put
    is_expected.to respond_to :delete
  end

  context 'when performing requests' do
    subject(:request) { api.request }

    it { is_expected.to be_a Hash }

    context 'when checking keys' do
      subject { request.keys }

      it { is_expected.to eq %w(next previous total per_page results) }
    end

    context 'when checking next value' do
      let(:request_next) { 'https://api.uploadcare.com/files' }

      subject { request['next'] }

      it { is_expected.to match request_next }
    end

    context 'when checking previous value' do
      subject { request['previous'] }

      it { is_expected.to be_nil }
    end

    context 'when checking total value' do
      subject { request['previous'] }

      it { is_expected.to be_nil }
    end

    context 'when checking per_page value' do
      subject { request['per_page'] }

      it { is_expected.to be 100 }
    end

    context 'when checking results' do
      subject(:results) { request['results'] }

      it { expect(results.count).to be 100 }

      context 'when checking one result' do
        let(:keys) do
          %w(uuid original_file_url image_info datetime_stored mime_type
             is_ready url original_filename datetime_uploaded size is_image
             datetime_removed source)
        end

        subject(:result) { results.sample }

        it { is_expected.to be_a Hash }
        it { expect(result.keys).to eq keys }
      end
    end
  end
end

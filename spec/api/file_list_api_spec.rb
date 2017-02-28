require 'spec_helper'

describe Uploadcare::FileListApi do
  let(:api){ API }
  subject{ api.file_list(limit: 1) }

  before(:each){ allow(api).to receive(:get){ {'results' => []} } }

  it 'returns a file list' do
    expect( subject ).to be_a(Uploadcare::Api::FileList)
  end

  it 'stores options in a file list object' do
    expect( subject.options ).to eq({limit: 1})
  end

  describe 'validation' do
    it 'passes validation when no options given' do
      expect{ api.file_list }.not_to raise_error
    end

    it "validates that options don't have unsupported keys" do
      expect{ api.file_list(unknown: 1) }.to raise_error(ArgumentError)
    end

    it 'validates that :limit is an integer from 1 to 1000' do
      expect{ api.file_list(limit: 1) }.not_to raise_error
      expect{ api.file_list(limit: 395) }.not_to raise_error
      expect{ api.file_list(limit: 1000) }.not_to raise_error

      expect{ api.file_list(limit: 1.0) }.to raise_error(ArgumentError)
      expect{ api.file_list(limit: -1) }.to raise_error(ArgumentError)
      expect{ api.file_list(limit: 0) }.to raise_error(ArgumentError)
      expect{ api.file_list(limit: 1001) }.to raise_error(ArgumentError)
      expect{ api.file_list(limit: false) }.to raise_error(ArgumentError)
    end

    it 'validates that :stored is a boolean' do
      expect{ api.file_list(stored: true) }.not_to raise_error
      expect{ api.file_list(stored: false) }.not_to raise_error

      expect{ api.file_list(stored: 'yes') }.to raise_error(ArgumentError)
    end

    it 'validates that :removed is a boolean' do
      expect{ api.file_list(removed: true) }.not_to raise_error
      expect{ api.file_list(removed: false) }.not_to raise_error

      expect{ api.file_list(removed: 'yes') }.to raise_error(ArgumentError)
    end

    valid_ordering = %w{size -size datetime_uploaded -datetime_uploaded}
    it "validates that :ordering is in [#{valid_ordering.join(', ')}]" do
      valid_ordering.each do |valid_value|
        expect{ api.file_list(ordering: valid_value) }.not_to raise_error
      end

      expect{ api.file_list(ordering: 'yes') }.to raise_error(ArgumentError)
    end

    describe 'from' do
      context 'when ordering is "size" or "-size"' do
        let(:opts){ {ordering: ['size', '-size'].sample} }

        it 'validates that :from is a non-negative integer' do
          valid = [0, 100500]
          valid.each do |value|
            expect{ api.file_list(opts.merge(from: value)) }.not_to raise_error
          end

          invalid = [-1, 200.0, "string", false]
          invalid.each do |value|
            expect{ api.file_list(opts.merge(from: value)) }.to raise_error(ArgumentError)
          end
        end
      end

      context 'when ordering is "datetime_uploaded", "-datetime_uploaded" or nil' do
        let(:opts){ {ordering: ['datetime_uploaded', '-datetime_uploaded', nil].sample} }

        it 'validates that :from.to_s is a iso8601 string' do
          valid = [DateTime.now, DateTime.now.iso8601, "2017-01-01T15"]
          valid.each do |value|
            expect{ api.file_list(opts.merge(from: value)) }.not_to raise_error
          end

          invalid = [Date.today, Time.now, DateTime.now.rfc2822, "2017-01-01", 123, false]
          invalid.each do |value|
            expect{ api.file_list(opts.merge(from: value)) }.to raise_error(ArgumentError)
          end
        end
      end
    end
  end
end

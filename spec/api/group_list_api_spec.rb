require 'spec_helper'

describe Uploadcare::GroupListApi do
  let(:api){ API }
  subject{ api.group_list(limit: 1) }

  before(:each){ allow(api).to receive(:get){ {'results' => []} } }

  it 'returns a group list' do
    expect( subject ).to be_a(Uploadcare::Api::GroupList)
  end

  it 'stores options in a group list object' do
    expect( subject.options ).to eq({limit: 1})
  end

  describe 'validation' do
    it 'passes validation when no options given' do
      expect{ api.group_list }.not_to raise_error
    end

    it "validates that options don't have unsupported keys" do
      expect{ api.group_list(unknown: 1) }.to raise_error(ArgumentError)
    end

    it 'validates that :limit is an integer from 1 to 1000' do
      [1, 359, 1000].each do |v|
        expect{ api.group_list(limit: v) }.not_to raise_error
      end

      [1.0, -1, 0, 1001, false].each do |v|
        expect{ api.group_list(limit: v) }.to raise_error(ArgumentError)
      end
    end

    valid_ordering = %w{datetime_created -datetime_created}
    it "validates that :ordering is in [#{valid_ordering.join(', ')}]" do
      valid_ordering.each do |valid_value|
        expect{ api.group_list(ordering: valid_value) }.not_to raise_error
      end

      expect{ api.group_list(ordering: 'yes') }.to raise_error(ArgumentError)
    end

    describe 'from' do
      it 'validates that :from.to_s is a iso8601 string' do
        valid = [DateTime.now, DateTime.now.iso8601, "2017-01-01T15"]
        valid.each do |value|
          expect{ api.group_list(from: value) }.not_to raise_error
        end

        invalid = [Date.today, Time.now, DateTime.now.rfc2822, "2017-01-01", 123, false]
        invalid.each do |value|
          expect{ api.group_list(from: value) }.to raise_error(ArgumentError)
        end
      end
    end
  end
end

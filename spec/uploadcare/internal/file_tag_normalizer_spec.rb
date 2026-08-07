# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::Internal::FileTagNormalizer do
  describe '.call' do
    it 'strips, lowercases, and deduplicates tags in first-seen order' do
      expect(described_class.call([' Cat ', 'ANIMAL', 'cat', 'v1.0'])).to eq(%w[cat animal v1.0])
    end

    it 'returns an empty array for an empty array' do
      expect(described_class.call([])).to eq([])
    end

    it 'accepts all supported characters' do
      expect(described_class.call(%w[tag-1 tag_2 v1.0])).to eq(%w[tag-1 tag_2 v1.0])
    end

    it 'rejects non-array tag lists and non-string tags' do
      expect { described_class.call(nil) }.to raise_error(ArgumentError, /array of strings/)
      expect { described_class.call('cat') }.to raise_error(ArgumentError, /array of strings/)
      expect { described_class.call(['cat', 1]) }.to raise_error(ArgumentError, /array of strings/)
    end

    it 'rejects blank tags' do
      expect { described_class.call(['  ']) }.to raise_error(ArgumentError, /may not be blank/)
    end

    it 'rejects tags longer than 100 characters' do
      expect { described_class.call(['a' * 101]) }.to raise_error(ArgumentError, /too long/)
    end

    it 'rejects unsupported characters' do
      ['has space', 'c++', 'emoji🐈', 'кот'].each do |tag|
        expect { described_class.call([tag]) }.to raise_error(ArgumentError, /invalid characters/)
      end
    end

    it 'counts tags after normalization and deduplication' do
      tags = Array.new(51, 'same')
      expect(described_class.call(tags)).to eq(['same'])

      unique_tags = 51.times.map { |index| "tag#{index}" }
      expect { described_class.call(unique_tags) }.to raise_error(ArgumentError, /too many tags/)
    end

    it 'can disable count validation for deletion lists' do
      tags = 51.times.map { |index| "tag#{index}" }
      expect(described_class.call(tags, max_count: nil)).to eq(tags)
    end
  end
end

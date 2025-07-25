# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploadcare::UrlBuilder do
  let(:config) do
    Uploadcare::Configuration.new(
      cdn_base: 'https://ucarecdn.com/'
    )
  end
  let(:uuid) { 'dc99200d-9bd6-4b43-bfa9-aa7bfaefca40' }

  subject(:builder) { described_class.new(uuid, config) }

  describe '#initialize' do
    context 'with UUID string' do
      it 'constructs base URL correctly' do
        expect(builder.base_url).to eq('https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40')
      end
    end

    context 'with File object' do
      let(:file) { Uploadcare::File.new({ uuid: uuid }, config) }
      subject(:builder) { described_class.new(file, config) }

      it 'constructs base URL from file' do
        expect(builder.base_url).to eq('https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40')
      end
    end

    context 'with full URL' do
      let(:url) { 'https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/' }
      subject(:builder) { described_class.new(url, config) }

      it 'uses the URL directly' do
        expect(builder.base_url).to eq('https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40')
      end
    end
  end

  describe 'resize operations' do
    it 'builds resize with width and height' do
      url = builder.resize(300, 200).url
      expect(url).to eq('https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/-/resize/300x200/')
    end

    it 'builds resize with width only' do
      url = builder.resize_width(300).url
      expect(url).to eq('https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/-/resize/300x/')
    end

    it 'builds resize with height only' do
      url = builder.resize_height(200).url
      expect(url).to eq('https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/-/resize/x200/')
    end

    it 'builds scale crop' do
      url = builder.scale_crop(300, 200).url
      expect(url).to eq('https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/-/scale_crop/300x200/')
    end

    it 'builds smart resize' do
      url = builder.smart_resize(300, 200).url
      expect(url).to eq('https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/-/scale_crop/300x200/smart/')
    end
  end

  describe 'crop operations' do
    it 'builds basic crop' do
      url = builder.crop(100, 100).url
      expect(url).to eq('https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/-/crop/100x100/')
    end

    it 'builds crop with offset' do
      url = builder.crop(100, 100, offset_x: 10, offset_y: 20).url
      expect(url).to eq('https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/-/crop/100x100/10,20/')
    end

    it 'builds face crop' do
      url = builder.crop_faces.url
      expect(url).to eq('https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/-/crop/faces/')
    end

    it 'builds face crop with ratio' do
      url = builder.crop_faces('16:9').url
      expect(url).to eq('https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/-/crop/faces/16:9/')
    end
  end

  describe 'format operations' do
    it 'converts format' do
      url = builder.format('webp').url
      expect(url).to eq('https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/-/format/webp/')
    end

    it 'sets quality' do
      url = builder.quality('smart').url
      expect(url).to eq('https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/-/quality/smart/')
    end

    it 'enables progressive' do
      url = builder.progressive.url
      expect(url).to eq('https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/-/progressive/yes/')
    end
  end

  describe 'effects and filters' do
    it 'applies grayscale' do
      url = builder.grayscale.url
      expect(url).to eq('https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/-/grayscale/')
    end

    it 'applies blur' do
      url = builder.blur(10).url
      expect(url).to eq('https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/-/blur/10/')
    end

    it 'applies rotation' do
      url = builder.rotate(90).url
      expect(url).to eq('https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/-/rotate/90/')
    end

    it 'applies brightness' do
      url = builder.brightness(50).url
      expect(url).to eq('https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/-/brightness/50/')
    end
  end

  describe 'chaining operations' do
    it 'chains multiple operations' do
      url = builder
            .resize(300, 200)
            .quality('smart')
            .format('webp')
            .grayscale
            .url

      expect(url).to eq('https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/-/resize/300x200/-/quality/smart/-/format/webp/-/grayscale/')
    end
  end

  describe 'filename' do
    it 'adds filename to URL' do
      url = builder.resize(300, 200).filename('custom-name.jpg').url
      expect(url).to eq('https://ucarecdn.com/dc99200d-9bd6-4b43-bfa9-aa7bfaefca40/-/resize/300x200/custom-name.jpg')
    end
  end

  describe 'aliases' do
    it 'responds to to_s' do
      expect(builder.resize(300, 200).to_s).to eq(builder.resize(300, 200).url)
    end

    it 'responds to to_url' do
      expect(builder.resize(300, 200).to_url).to eq(builder.resize(300, 200).url)
    end
  end
end

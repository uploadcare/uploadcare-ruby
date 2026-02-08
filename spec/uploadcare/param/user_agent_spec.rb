# frozen_string_literal: true

RSpec.describe Uploadcare::Param::UserAgent do
  it 'builds user agent string with framework data' do
    config = Uploadcare::Configuration.new(public_key: 'pub', framework_data: 'Rails/8.0.0')
    result = described_class.call(config: config)

    expect(result).to include('UploadcareRuby/')
    expect(result).to include('/pub (Ruby/')
    expect(result).to include('; Rails/8.0.0')
  end

  it 'builds user agent string without framework data' do
    config = Uploadcare::Configuration.new(public_key: 'pub', framework_data: '')
    result = described_class.call(config: config)

    expect(result).to include('/pub (Ruby/')
    expect(result).not_to include('; ')
  end
end

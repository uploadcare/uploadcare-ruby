# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Multi-account configuration' do
  let(:config1) do
    Uploadcare::Configuration.new(
      public_key: 'public_key1',
      secret_key: 'secret_key1',
      use_subdomains: true,
      cdn_base_postfix: 'https://ucarecd.net/'
    )
  end

  let(:config2) do
    Uploadcare::Configuration.new(
      public_key: 'public_key2',
      secret_key: 'secret_key2',
      use_subdomains: true,
      cdn_base_postfix: 'https://ucarecd.net/'
    )
  end

  it 'generates different CDN bases per Configuration instance' do
    base1 = config1.cdn_base.call
    base2 = config2.cdn_base.call

    expect(base1).not_to eq(base2)
    expect(base1).to match(%r{\Ahttps://[0-9a-z]{10}\.ucarecd\.net/\z})
    expect(base2).to match(%r{\Ahttps://[0-9a-z]{10}\.ucarecd\.net/\z})
  end

  it 'uses the instance config when building resource CDN URLs' do
    file1 = Uploadcare::File.new({ uuid: 'uuid-1' }, config1)
    file2 = Uploadcare::File.new({ uuid: 'uuid-2' }, config2)

    expect(file1.cdn_url).to start_with(config1.cdn_base.call)
    expect(file2.cdn_url).to start_with(config2.cdn_base.call)
    expect(file1.cdn_url).not_to start_with(config2.cdn_base.call)
    expect(file2.cdn_url).not_to start_with(config1.cdn_base.call)
  end

  it 'generates secure auth headers using the client config' do
    config1.auth_type = 'Uploadcare'
    config2.auth_type = 'Uploadcare'

    auth1 = Uploadcare::Authenticator.new(config: config1)
    auth2 = Uploadcare::Authenticator.new(config: config2)

    allow(Time).to receive(:now).and_return(Time.at(0))

    h1 = auth1.headers('GET', '/files/', '')
    h2 = auth2.headers('GET', '/files/', '')

    expect(h1['Authorization']).to start_with("Uploadcare #{config1.public_key}:")
    expect(h2['Authorization']).to start_with("Uploadcare #{config2.public_key}:")
    expect(h1['Authorization']).not_to eq(h2['Authorization'])
  end
end

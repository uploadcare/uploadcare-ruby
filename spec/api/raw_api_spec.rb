require 'spec_helper'
require 'uri'
require 'socket'

describe Uploadcare::Api, :vcr do
  let(:subject) { Uploadcare::Api.new(CONFIG) }


  it { is_expected.to be_an_instance_of(Uploadcare::Api) }
  it { is_expected.to respond_to(:request) }
  it { is_expected.to respond_to(:get) }
  it { is_expected.to respond_to(:post) }
  it { is_expected.to respond_to(:put) }
  it { is_expected.to respond_to(:delete) }

  it 'should perform custom requests' do
    expect { subject.request }.to_not raise_error
  end
end

require 'spec_helper'
# require 'uri'
# require 'socket'

describe Uploadcare::Api::GroupList do
  before :all do
    @api = API

    # ensure that current project has at least two groups
    if @api.get('/groups/', limit: 2)['results'].size < 2
      (2 - count).times{ @api.create_group([@api.upload(IMAGE_URL)]) }
    end

    @list = @api.group_list(limit: 1)
  end

  let(:resource_class){ Uploadcare::Api::Group }
  subject{ @list }

  it_behaves_like 'resource list'

  describe '#objects' do
    subject{ @list.objects }

    it{ is_expected.to all(be_a(resource_class)) }
    it{ is_expected.not_to include(be_loaded) }
  end
end

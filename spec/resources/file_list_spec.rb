require 'spec_helper'

describe Uploadcare::Api::FileList do
  before :all do
    @api = API

    # ensure that current project has at least two files
    count = @api.get('/files/', limit: 2)['results'].size
    (2 - count).times{ @api.upload(IMAGE_URL) } if count < 2

    @list = @api.file_list(limit: 1)
  end

  let(:resource_class){ Uploadcare::Api::File }
  subject{ @list }

  it_behaves_like 'resource list'

  describe '#objects' do
    subject{ @list.objects }

    it{ is_expected.to all(be_a(resource_class)) }
    it{ is_expected.to all(be_loaded) }
  end
end

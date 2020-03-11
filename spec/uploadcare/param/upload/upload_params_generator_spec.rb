# @see https://uploadcare.com/docs/api_reference/upload/signed_uploads/

require 'spec_helper'

module Uploadcare
  module Param
    module Upload
      RSpec.describe Uploadcare::Upload::UploadParamsGenerator do
        subject { Uploadcare::Upload::UploadParamsGenerator }
        before do
          SIGN_UPLOADS = false
        end

        it 'generates basic upload params headers' do
          params = subject.call
          expect(params['UPLOADCARE_PUB_KEY']).not_to be_nil
          expect(params['UPLOADCARE_STORE']).not_to be_nil
        end
      end
    end
  end
end

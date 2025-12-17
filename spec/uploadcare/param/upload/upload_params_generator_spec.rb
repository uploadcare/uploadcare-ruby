# frozen_string_literal: true

# @see https://uploadcare.com/docs/api_reference/upload/signed_uploads/

require 'spec_helper'
require 'param/upload/upload_params_generator'

module Uploadcare
  module Param
    module Upload
      RSpec.describe Uploadcare::Param::Upload::UploadParamsGenerator do
        subject { Uploadcare::Param::Upload::UploadParamsGenerator }

        it 'generates basic upload params headers' do
          params = subject.call
          expect(params['UPLOADCARE_PUB_KEY']).not_to be_nil
          expect(params['UPLOADCARE_STORE']).not_to be_nil
        end

        it 'generates upload params with signature if sign_uploads is true' do
          Uploadcare.config.sign_uploads = true
          params = subject.call
          expect(params['signature']).not_to be_nil
          expect(params['expire']).not_to be_nil
        end
      end
    end
  end
end

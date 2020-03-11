# @see https://uploadcare.com/docs/api_reference/upload/signed_uploads/

require 'spec_helper'

module Uploadcare
  module Param
    module Upload
      RSpec.describe Uploadcare::Upload::SignatureGenerator do
        let!(:expires_at) { 1454903856 }
        let!(:expected_result) { { signature: '46f70d2b4fb6196daeb2c16bf44a7f1e', expire: expires_at } }

        before do
          allow(Time).to receive(:now).and_return(expires_at - 60 * 30)
          Uploadcare.configuration.secret_key = 'project_secret_key'
        end

        it 'generates body params needed for signing uploads' do
          signature_body = SignatureGenerator.call
          expect(signature_body).to eq expected_result
        end
      end
    end
  end
end

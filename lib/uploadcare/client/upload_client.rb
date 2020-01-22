# frozen_string_literal: true

module Uploadcare
  # This is client for general uploads
  # https://uploadcare.com/api-refs/upload-api/#tag/Upload
  class UploadClient < ApiStruct::Client
    upload_api

    # https://uploadcare.com/api-refs/upload-api/#operation/baseUpload

    def upload_many(arr, **options)
      body = HTTP::FormData::Multipart.new(
        upload_params(options[:store]).merge(files_formdata(arr))
      )
      response = post(path: 'base/',
           headers: { 'Content-type': body.content_type },
           body: body)
      response.fmap { |files| { 'files': files.map { |fname, uuid| { original_filename: fname.to_s, uuid: uuid } } } }
    end

    private

    def upload_params(store = 'auto')
      store = '1' if store == true
      store = '0' if store == false
      {
        'UPLOADCARE_PUB_KEY': PUBLIC_KEY,
        'UPLOADCARE_STORE': store
      }
    end

    def files_formdata(arr)
      arr.map { |file| [HTTP::FormData::File.new(file).filename,
                        HTTP::FormData::File.new(file)] }.to_h
    end
  end
end

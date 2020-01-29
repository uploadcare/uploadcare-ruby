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
      post(path: 'base/',
           headers: { 'Content-type': body.content_type },
           body: body)
    end

    private

    def upload_params(store = false)
      {
        'UPLOADCARE_PUB_KEY': PUBLIC_KEY,
        'UPLOADCARE_STORE': (store == true) ? '1' : '0'
      }
    end

    def files_formdata(arr)
      arr.map { |file| [HTTP::FormData::File.new(file).filename,
                        HTTP::FormData::File.new(file)] }.to_h
    end
  end
end

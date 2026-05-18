# frozen_string_literal: true

RSpec.describe 'Uploadcare exceptions' do
  it 'initializes ThrottleError with timeout' do
    error = Uploadcare::Exception::ThrottleError.new(timeout: 3.5)

    expect(error.timeout).to eq(3.5)
  end

  it 'defines core exception classes' do
    expect(Uploadcare::Exception::AuthError).to be < StandardError
    expect(Uploadcare::Exception::ConversionError).to be < StandardError
    expect(Uploadcare::Exception::RequestError).to be < StandardError
    expect(Uploadcare::Exception::RetryError).to be < StandardError
  end
end

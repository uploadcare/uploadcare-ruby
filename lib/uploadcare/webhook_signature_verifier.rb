# frozen_string_literal: true

require 'openssl'

# This object verifies a signature received along with webhook headers
class Uploadcare::WebhookSignatureVerifier
  # @see https://uploadcare.com/docs/security/secure-webhooks/
  def self.valid?(webhook_body: nil, signing_secret: nil, x_uc_signature_header: nil)
    webhook_body_json = webhook_body
    signing_secret ||= ENV.fetch('UC_SIGNING_SECRET', nil)

    return false unless valid_parameters?(signing_secret, x_uc_signature_header, webhook_body_json)

    calculated_signature = calculate_signature(signing_secret, webhook_body_json)

    # Use constant-time comparison to prevent timing attacks
    secure_compare?(calculated_signature, x_uc_signature_header)
  end

  # Check if all required parameters are present and non-empty
  # @param signing_secret [String] signing secret
  # @param signature_header [String] signature from header
  # @param body [String] webhook body
  # @return [Boolean] true if all parameters are valid
  def self.valid_parameters?(signing_secret, signature_header, body)
    return false if signing_secret.nil? || signing_secret.to_s.empty?
    return false if signature_header.nil? || signature_header.to_s.empty?
    return false if body.nil? || body.to_s.empty?

    true
  end

  # Calculate HMAC signature for webhook body
  # @param secret [String] signing secret
  # @param body [String] webhook body JSON
  # @return [String] calculated signature
  def self.calculate_signature(secret, body)
    digest = OpenSSL::Digest.new('sha256')
    "v1=#{OpenSSL::HMAC.hexdigest(digest, secret, body)}"
  end

  # Constant-time string comparison to prevent timing attacks
  # @param first [String] first string
  # @param second [String] second string
  # @return [Boolean] true if strings are equal
  def self.secure_compare?(first, second)
    return false unless first.bytesize == second.bytesize

    left = first.unpack('C*')
    res = 0
    second.each_byte { |byte| res |= byte ^ left.shift }
    res.zero?
  end
end

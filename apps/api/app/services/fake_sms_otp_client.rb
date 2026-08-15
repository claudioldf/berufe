# frozen_string_literal: true

require "openssl"
require "securerandom"

class FakeSmsOtpClient
  REFERENCE_PATTERN = /\Afake_[0-9a-f]{32}\z/

  def initialize(code:)
    @code = code.to_s
  end

  def start_challenge(phone:)
    raise ArgumentError, "phone is required" if phone.to_s.empty?

    SmsOtp::Challenge.new(reference: "fake_#{SecureRandom.hex(16)}", status: "accepted")
  end

  def verify_challenge(reference:, code:)
    valid_reference = REFERENCE_PATTERN.match?(reference.to_s)
    supplied_code = code.to_s
    valid_code = supplied_code.bytesize == @code.bytesize && OpenSSL.fixed_length_secure_compare(supplied_code, @code)

    SmsOtp::Verification.new(
      verified: valid_reference && valid_code,
      status: (valid_reference && valid_code) ? "verified" : "not_verified"
    )
  end
end

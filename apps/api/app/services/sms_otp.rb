# frozen_string_literal: true

module SmsOtp
  Challenge = Data.define(:reference, :status)
  Verification = Data.define(:verified, :status)

  class Error < StandardError; end
  class DeliveryRejected < Error; end
  class ProviderUnavailable < Error; end

  class RateLimited < Error
    attr_reader :retry_after

    def initialize(retry_after: nil)
      @retry_after = retry_after
      super("SMS OTP provider rate limit reached")
    end
  end
end

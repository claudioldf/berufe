# frozen_string_literal: true

module EmailOtp
  class DeliveryRejected < StandardError; end
  class ProviderUnavailable < StandardError; end
end

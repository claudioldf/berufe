# frozen_string_literal: true

module Berufe
  module MailDelivery
    class Error < StandardError; end

    # The provider rejected the message outright (bad request, auth failure,
    # unverified domain, quota exhausted). Retrying will not help.
    class Rejected < Error; end

    # The provider or the network is temporarily unavailable (timeout,
    # connection failure, rate limit, 5xx). Safe to retry.
    class ProviderUnavailable < Error; end
  end
end

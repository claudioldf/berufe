# frozen_string_literal: true

class EmailOtpDelivery
  def call(email:, code:, expires_in:)
    EmailOtpMailer.with(email:, code:, expires_in:).verification_code.deliver_now
  rescue Berufe::MailDelivery::Rejected
    raise EmailOtp::DeliveryRejected
  rescue Berufe::MailDelivery::ProviderUnavailable, Net::SMTPError, Timeout::Error,
    SocketError, SystemCallError
    raise EmailOtp::ProviderUnavailable
  end
end

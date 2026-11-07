# frozen_string_literal: true

class SupportMessageDeliveryJob < ApplicationJob
  queue_as :default

  retry_on Berufe::MailDelivery::ProviderUnavailable,
    wait: :polynomially_longer,
    attempts: 5
  discard_on Berufe::MailDelivery::Rejected

  def perform(email, message, mailer: SupportMessageMailer)
    attributes = message.symbolize_keys
    mail = mailer.with(recipient: email, **attributes).received
    mail.message_id = "<support-#{SecureRandom.hex(8)}-#{Digest::SHA256.hexdigest(email)[0, 12]}@berufe.com.br>"
    begin
      mail.deliver_now
    rescue Berufe::MailDelivery::Error => error
      Rails.error.report(error, context: {event: "support_message", topic: attributes[:topic]})
      raise
    end
  end
end

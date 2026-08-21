# frozen_string_literal: true

require "net/smtp"
require "timeout"

class CustomerRecommendationRequestDeliveryJob < ApplicationJob
  queue_as :default

  retry_on Net::SMTPError, Timeout::Error, SocketError,
    wait: :polynomially_longer,
    attempts: 5

  def perform(request_id)
    request_record = CustomerRecommendationRequest
      .includes(service_job: {quote: :professional})
      .find_by(id: request_id)
    return unless request_record

    request_record.with_lock do
      return unless request_record.open_at?
      return if request_record.sent_at.present?

      token = CustomerRecommendationToken.decrypt(request_record.token_ciphertext)
      return unless token

      CustomerRecommendationMailer.with(request_record:, token:).invitation.deliver_now
      request_record.update!(sent_at: Time.current, token_ciphertext: nil)
    end
  end
end

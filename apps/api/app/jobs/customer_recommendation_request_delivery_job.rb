# frozen_string_literal: true

class CustomerRecommendationRequestDeliveryJob < ApplicationJob
  queue_as :default

  retry_on Berufe::MailDelivery::ProviderUnavailable,
    wait: :polynomially_longer,
    attempts: 5
  discard_on Berufe::MailDelivery::Rejected

  def perform(request_id, mailer: CustomerRecommendationMailer)
    request_record = CustomerRecommendationRequest
      .includes(service_job: {quote: :professional})
      .find_by(id: request_id)
    return unless request_record

    token = nil
    request_record.with_lock do
      return unless request_record.email_channel?
      return unless request_record.open_at?
      return if request_record.sent_at.present?

      token = CustomerRecommendationToken.decrypt(request_record.token_ciphertext)
    end
    return unless token

    # Delivery runs outside the row lock: production runs a single in-process
    # job thread (GOOD_JOB_MAX_THREADS=1), so a slow or stalled provider
    # request must not hold the row lock, a pool connection, and the only
    # worker thread all at once. The Message-ID is pinned to the request so a
    # retry after a successful-but-uncommitted send is deduplicated by the
    # provider rather than re-delivered.
    mail = mailer.with(request_record:, token:).invitation
    mail.message_id = "<customer-recommendation-#{request_record.id}@berufe.com.br>"
    begin
      mail.deliver_now
    rescue Berufe::MailDelivery::Error => error
      Rails.error.report(error, context: {customer_recommendation_request_id: request_id})
      raise
    end

    request_record.with_lock do
      next if request_record.sent_at.present?

      request_record.update!(sent_at: Time.current, token_ciphertext: nil)
    end
  end
end

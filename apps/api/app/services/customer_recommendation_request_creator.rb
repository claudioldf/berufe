# frozen_string_literal: true

# Creates the one recommendation request a completed service job is allowed
# to have (idx_recommendation_requests_unique_job), regardless of whether the
# quote's customer snapshot has an email. The bearer token it issues serves
# both delivery channels: email delivery is scheduled automatically, and
# WhatsApp delivery is handed to the professional through
# ProfessionalServiceJobRecommendationRequester.
class CustomerRecommendationRequestCreator
  EXPIRY = 14.days
  EMAIL_DELIVERY_DELAY = 4.hours

  def call(service_job:, now: Time.current)
    existing = service_job.customer_recommendation_request
    return existing if existing

    quote = service_job.quote
    channel = quote.customer_email.present? ? "email" : "whatsapp"
    token_value = CustomerRecommendationToken.issue
    request = service_job.create_customer_recommendation_request!(
      token_hash: CustomerRecommendationToken.digest(token_value),
      token_ciphertext: CustomerRecommendationToken.encrypt(token_value),
      email_fingerprint: (CustomerEmailFingerprint.call(quote.customer_email) if channel == "email"),
      delivery_channel: channel,
      expires_at: now + EXPIRY
    )
    CustomerRecommendationRequestDeliveryJob.set(wait: EMAIL_DELIVERY_DELAY).perform_later(request.id) if channel == "email"
    request
  end
end

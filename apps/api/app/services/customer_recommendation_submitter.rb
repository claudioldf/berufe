# frozen_string_literal: true

class CustomerRecommendationSubmitter
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid customer recommendation")
    end
  end

  class Unavailable < StandardError; end

  def initialize(notifier: ProfessionalNotificationCreator.new)
    @notifier = notifier
  end

  def call(token:, attributes:, now: Time.current)
    request = CustomerRecommendationResolver.new.call(token:, now:)
    validate_attributes!(attributes)
    recommendation = nil

    ApplicationRecord.transaction do
      request.lock!
      raise Unavailable unless request.open_at?(now)

      quote = request.service_job.quote
      customer = quote.customer
      recommendation = CustomerRecommendation.create!(
        service_job: request.service_job,
        customer:,
        display_name: attributes[:display_name],
        recommendation_text: attributes[:recommendation_text],
        email_fingerprint: request.email_fingerprint,
        email_verified_at: now,
        service_confirmed_at: now,
        publication_authorized_at: now,
        privacy_notice_version: LegalDocumentVersions::PRIVACY_NOTICE,
        submitted_at: now
      )
      request.update!(status: "completed", completed_at: now, token_ciphertext: nil)

      current_fingerprint = CustomerEmailFingerprint.call(customer.email) if customer.email.present?
      snapshot_fingerprint = CustomerEmailFingerprint.call(quote.customer_email)
      if current_fingerprint == snapshot_fingerprint && snapshot_fingerprint == request.email_fingerprint
        customer.update!(email_verified_at: now)
      end
      professional = request.service_job.professional
      @notifier.call(
        recipient: professional.user_account,
        notification_type: "customer_recommendation_published",
        idempotency_key: "customer-recommendation:#{recommendation.id}:published",
        occurred_at: now
      )
    end

    recommendation
  rescue ActiveRecord::RecordInvalid => error
    raise Invalid.new(error.record.errors.to_hash(true))
  end

  private

  def validate_attributes!(attributes)
    errors = {}
    display_name = attributes[:display_name].to_s.squish
    text = attributes[:recommendation_text].to_s.squish
    errors[:display_name] = ["deve ter entre 1 e 80 caracteres"] unless display_name.length.between?(1, 80)
    errors[:recommendation_text] = ["deve ter entre 1 e 700 caracteres"] unless text.length.between?(1, 700)
    errors[:service_confirmed] = ["deve ser confirmado"] unless attributes[:service_confirmed] == true
    errors[:publication_consent] = ["deve ser autorizado"] unless attributes[:publication_consent] == true
    raise Invalid.new(errors) if errors.any?
  end
end

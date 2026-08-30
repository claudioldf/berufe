# frozen_string_literal: true

class SharedQuoteCompletionResponder
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid shared quote completion response")
    end
  end

  class Unavailable < StandardError; end

  RESPONSES = %w[confirm report_issue].freeze
  Result = Data.define(:resolved, :recommendation_request_created)

  def initialize(notifier: ProfessionalNotificationCreator.new)
    @notifier = notifier
  end

  def call(token:, response:, message:, now: Time.current)
    resolved = SharedQuoteResolver.new.call(token:)
    response = response.to_s
    raise Invalid.new(response: ["não é válida"]) unless response.in?(RESPONSES)

    request_created = false
    recommendation_request = nil
    job = resolved.quote.service_job
    raise Unavailable unless job

    ApplicationRecord.transaction do
      job.lock!
      if response == "confirm" && job.completed?
        next
      end
      raise Unavailable unless job.completion_requested?

      normalized_message = message.to_s.squish
      if response == "report_issue"
        raise Invalid.new(message: ["explique o que ainda precisa ser resolvido"]) if normalized_message.blank?
        raise Invalid.new(message: ["deve ter no máximo 700 caracteres"]) if normalized_message.length > 700

        job.update!(
          status: "completion_issue",
          completion_issue_at: now,
          completion_issue_message: normalized_message
        )
      else
        job.update!(
          status: "completed",
          completed_at: now,
          completion_confirmed_by: "customer"
        )
        if resolved.quote.customer_email.present? && job.customer_recommendation_request.nil?
          token_value = CustomerRecommendationToken.issue
          recommendation_request = job.create_customer_recommendation_request!(
            token_hash: CustomerRecommendationToken.digest(token_value),
            token_ciphertext: CustomerRecommendationToken.encrypt(token_value),
            email_fingerprint: CustomerEmailFingerprint.call(resolved.quote.customer_email),
            expires_at: now + 14.days
          )
          request_created = true
        end
      end
      @notifier.call(
        recipient: job.professional.user_account,
        notification_type: (response == "confirm") ? "service_completion_confirmed" : "service_completion_issue_reported",
        route: "/app/professional/services/#{job.id}",
        idempotency_key: "service-job:#{job.id}:completion:#{job.completion_requested_at&.iso8601(6)}:#{response}",
        occurred_at: now
      )
    end

    CustomerRecommendationRequestDeliveryJob.perform_later(recommendation_request.id) if request_created
    Result.new(
      resolved: SharedQuoteResolver.new.call(token:),
      recommendation_request_created: request_created
    )
  end
end

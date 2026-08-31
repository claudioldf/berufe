# frozen_string_literal: true

# The private branch of the post-completion feedback ask (S067): the
# customer reports something outstanding instead of recommending. This never
# changes the service job's status — `completed` stays terminal — and never
# becomes public. It exists so an unhappy customer has an outlet other than a
# public recommendation, which is what keeps immediate, unmoderated
# publication acceptable.
class CustomerFeedbackIssueSubmitter
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid customer feedback issue")
    end
  end

  def initialize(notifier: ProfessionalNotificationCreator.new)
    @notifier = notifier
  end

  def call(token:, message:, now: Time.current)
    request = CustomerRecommendationResolver.new.call(token:, now:)
    normalized_message = message.to_s.squish
    raise Invalid.new(message: ["explique o que ainda precisa ser resolvido"]) if normalized_message.blank?
    raise Invalid.new(message: ["deve ter no máximo 700 caracteres"]) if normalized_message.length > 700

    service_job = request.service_job
    service_job.with_lock do
      service_job.update!(customer_feedback_message: normalized_message)
      @notifier.call(
        recipient: service_job.professional.user_account,
        notification_type: "service_completion_issue_reported",
        route_params: {service_job_id: service_job.id},
        idempotency_key: "service-job:#{service_job.id}:feedback-issue:#{Digest::SHA256.hexdigest(normalized_message)}",
        occurred_at: now
      )
    end
    request
  end
end

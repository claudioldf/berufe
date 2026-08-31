# frozen_string_literal: true

class ModerationDecision
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid moderation decision")
    end
  end

  class Conflict < StandardError; end

  IDENTITY_LABEL = "Identidade verificada"

  def initialize(context: Current.admin_action_context, notifier: ProfessionalNotificationCreator.new)
    @context = context
    @notifier = notifier
  end

  def call(target_type:, target_id:, action:, reason: nil, note: nil, identity_match_confirmed: nil)
    normalized = normalize(action:, reason:, note:, identity_match_confirmed:)
    request_record = ModerationTargetResolver.new.call(target_type:, target_id:)

    ApplicationRecord.transaction do
      request_record.lock!
      transition!(request_record, normalized)
      action_record = ModerationAction.create!(
        admin_user_id: context.admin_user_id,
        target_type: "verification_request",
        target_id: request_record.id,
        action: normalized[:action],
        reason: normalized[:reason],
        note: normalized[:note],
        request_id: context.request_id,
        created_at: Time.current
      )
      notifier.call(
        recipient: request_record.professional_profile.user_account,
        notification_type: "verification_request_moderation_#{action_record.action}",
        idempotency_key: "moderation-action:#{action_record.id}",
        occurred_at: action_record.created_at
      )
    end

    request_record.reload
  rescue ActiveRecord::RecordInvalid => error
    raise Invalid.new(error.record.errors.to_hash(true))
  end

  private

  attr_reader :context, :notifier

  def normalize(action:, reason:, note:, identity_match_confirmed:)
    normalized_action = action.to_s
    normalized_reason = reason.to_s.squish.presence
    normalized_note = note.to_s.squish.presence
    errors = {}
    errors[:action] = ["use uma decisão válida"] unless normalized_action.in?(%w[approved rejected])
    if normalized_action == "rejected" && !normalized_reason&.length.to_i.between?(10, 500)
      errors[:reason] = ["informe um motivo entre 10 e 500 caracteres"]
    end
    errors[:note] = ["use uma nota com até 500 caracteres"] if normalized_note&.length.to_i > 500
    raise Invalid.new(errors) if errors.any?

    {
      action: normalized_action,
      reason: (normalized_action == "rejected") ? normalized_reason : nil,
      note: normalized_note,
      identity_match_confirmed: identity_match_confirmed == true || identity_match_confirmed == "true"
    }
  end

  def transition!(request_record, attributes)
    raise Conflict, "moderation target changed" unless request_record.status == "pending_review"

    case attributes[:action]
    when "approved"
      unless attributes[:identity_match_confirmed]
        raise Invalid.new(identity_match_confirmed: ["confirme que a identidade corresponde ao perfil"])
      end
      raise Conflict, "identity birthdate is unavailable" if request_record.claimed_birthdate.blank?

      request_record.update!(
        status: "approved",
        reviewed_at: Time.current,
        reviewed_by_user_account_id: context.admin_user_id,
        review_note: attributes[:note],
        public_label: IDENTITY_LABEL,
        identity_match_confirmed_at: Time.current,
        verified_at: Time.current
      )
    when "rejected"
      request_record.update!(
        status: "rejected",
        reviewed_at: Time.current,
        reviewed_by_user_account_id: context.admin_user_id,
        review_note: attributes[:reason],
        public_label: nil,
        identity_match_confirmed_at: nil,
        verified_at: nil
      )
    end
  end
end

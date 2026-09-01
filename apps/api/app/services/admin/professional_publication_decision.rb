# frozen_string_literal: true

module Admin
  class ProfessionalPublicationDecision
    class Invalid < StandardError
      attr_reader :field_errors

      def initialize(field_errors)
        @field_errors = field_errors
        super("invalid professional publication decision")
      end
    end

    class Conflict < StandardError; end

    def initialize(context: Current.admin_action_context, notifier: ProfessionalNotificationCreator.new)
      @context = context
      @notifier = notifier
    end

    def call(professional_profile_id:, published:, reason: nil)
      normalized_reason = reason.to_s.squish.presence
      normalized_published = normalize_published(published)
      raise Invalid.new(published: ["deve ser verdadeiro ou falso"]) if normalized_published.nil?

      ApplicationRecord.transaction do
        profile = ProfessionalProfile.lock.find(professional_profile_id)
        normalized_published ? publish!(profile) : unpublish!(profile, reason: normalized_reason)
        profile
      end
    end

    private

    attr_reader :context, :notifier

    def normalize_published(value)
      case value
      when true, "true" then true
      when false, "false" then false
      end
    end

    def publish!(profile)
      raise Conflict, "professional profile is not suspended" unless profile.profile_status == "suspended"
      raise Conflict, "professional profile has no published revision" if profile.published_revision_id.blank?

      profile.update!(profile_status: "published")
      action_record = ModerationAction.create!(
        admin_user_id: context.admin_user_id,
        target_type: "professional_profile",
        target_id: profile.id,
        action: "restored",
        request_id: context.request_id,
        created_at: Time.current
      )
      notify!(profile, action_record)
    end

    def unpublish!(profile, reason:)
      raise Conflict, "professional profile is not published" unless profile.profile_status == "published"
      raise Conflict, "professional profile has no published revision" if profile.published_revision_id.blank?
      unless reason&.length&.between?(10, 500)
        raise Invalid.new(reason: ["informe um motivo entre 10 e 500 caracteres"])
      end

      profile.update!(profile_status: "suspended")
      action_record = ModerationAction.create!(
        admin_user_id: context.admin_user_id,
        target_type: "professional_profile",
        target_id: profile.id,
        action: "hidden",
        reason:,
        request_id: context.request_id,
        created_at: Time.current
      )
      notify!(profile, action_record)
    end

    def notify!(profile, action_record)
      notifier.call(
        recipient: profile.user_account,
        notification_type: "profile_moderation_#{action_record.action}",
        idempotency_key: "moderation-action:#{action_record.id}",
        occurred_at: action_record.created_at
      )
    end
  end
end

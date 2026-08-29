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

    def initialize(context: Current.admin_action_context)
      @context = context
    end

    def call(professional_profile_id:, published:, reason: nil)
      normalized_reason = reason.to_s.squish.presence
      normalized_published = normalize_published(published)
      raise Invalid.new(published: ["deve ser verdadeiro ou falso"]) if normalized_published.nil?

      profile = ProfessionalProfile.lock.find(professional_profile_id)
      normalized_published ? publish!(profile) : unpublish!(profile, reason: normalized_reason)
      profile
    end

    private

    attr_reader :context

    def normalize_published(value)
      case value
      when true, "true" then true
      when false, "false" then false
      end
    end

    def publish!(profile)
      raise Conflict, "professional profile is not suspended" unless profile.profile_status == "suspended"
      raise Conflict, "professional profile has no published revision" if profile.published_revision_id.blank?

      ApplicationRecord.transaction do
        profile.update!(profile_status: "published")
        ModerationAction.create!(
          admin_user_id: context.admin_user_id,
          target_type: "profile_revision",
          target_id: profile.published_revision_id,
          action: "restored",
          request_id: context.request_id,
          created_at: Time.current
        )
      end
    end

    def unpublish!(profile, reason:)
      raise Conflict, "professional profile is not published" unless profile.profile_status == "published"
      raise Conflict, "professional profile has no published revision" if profile.published_revision_id.blank?
      unless reason&.length&.between?(10, 500)
        raise Invalid.new(reason: ["informe um motivo privado entre 10 e 500 caracteres"])
      end

      ApplicationRecord.transaction do
        profile.update!(profile_status: "suspended")
        ModerationAction.create!(
          admin_user_id: context.admin_user_id,
          target_type: "profile_revision",
          target_id: profile.published_revision_id,
          action: "hidden",
          reason:,
          request_id: context.request_id,
          created_at: Time.current
        )
      end
    end
  end
end

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

  def initialize(context: Current.admin_action_context, publisher: ModerationMediaPublisher.new)
    @context = context
    @publisher = publisher
  end

  def call(target_type:, target_id:, action:, reason: nil, note: nil, identity_match_confirmed: nil)
    normalized = normalize(action:, reason:, note:, identity_match_confirmed:)
    target = ModerationTargetResolver.new.call(target_type:, target_id:)
    public_keys_to_delete = []
    created_public_keys = []

    ApplicationRecord.transaction do
      target.lock!
      transition!(target:, target_type:, attributes: normalized, public_keys_to_delete:, created_public_keys:)
      ModerationAction.create!(
        admin_user_id: context.admin_user_id,
        target_type:,
        target_id: target.id,
        action: normalized[:action],
        reason: normalized[:reason],
        note: normalized[:note],
        request_id: context.request_id,
        created_at: Time.current
      )
    end
    public_keys_to_delete.each { |public_key| publisher.delete(public_key) }
    target.reload
  rescue ActiveRecord::RecordInvalid => error
    cleanup_created_public_keys(created_public_keys)
    raise Invalid.new(error.record.errors.to_hash(true))
  rescue
    cleanup_created_public_keys(created_public_keys)
    raise
  end

  private

  attr_reader :context, :publisher

  def normalize(action:, reason:, note:, identity_match_confirmed:)
    normalized_action = action.to_s
    normalized_reason = reason.to_s.squish.presence
    normalized_note = note.to_s.squish.presence
    errors = {}
    errors[:action] = ["use uma decisão válida"] unless ModerationAction::ACTIONS.include?(normalized_action)
    if normalized_action.in?(%w[rejected hidden]) && !normalized_reason&.length.to_i.between?(10, 500)
      errors[:reason] = ["informe um motivo privado entre 10 e 500 caracteres"]
    end
    errors[:note] = ["use uma nota com até 500 caracteres"] if normalized_note&.length.to_i > 500
    raise Invalid.new(errors) if errors.any?

    {
      action: normalized_action,
      reason: normalized_reason,
      note: normalized_note,
      identity_match_confirmed: identity_match_confirmed == true || identity_match_confirmed == "true"
    }
  end

  def transition!(target:, target_type:, attributes:, public_keys_to_delete:, created_public_keys:)
    case target_type
    when "profile_revision"
      transition_revision!(target, attributes)
    when "profile_photo"
      transition_photo!(target, attributes, public_keys_to_delete, created_public_keys)
    when "portfolio_item"
      transition_portfolio!(target, attributes, public_keys_to_delete, created_public_keys)
    when "verification_request"
      transition_verification!(target, attributes)
    else
      raise ActiveRecord::RecordNotFound, "moderation target"
    end
  end

  def transition_revision!(revision, attributes)
    profile = revision.professional_profile.lock!
    case attributes[:action]
    when "approved"
      require_status!(revision.status, "pending_review")
      raise Conflict, "profile revision is not current" unless profile.published_revision_id == revision.id

      previous = profile.approved_revision
      previous.update!(status: "superseded") if previous && previous != revision
      revision.update!(status: "approved", reviewed_at: Time.current, rejection_reason: nil)
      profile_attributes = {
        approved_revision: revision,
        profile_status: "published"
      }
      profile_attributes[:working_revision] = revision unless
        revision.external? && profile.working_revision&.self_service?
      profile_attributes[:published_at] = profile.published_at || Time.current if revision.self_service?
      profile.update!(profile_attributes)
    when "rejected"
      require_status!(revision.status, "pending_review")
      raise Conflict, "profile revision is not current" unless profile.published_revision_id == revision.id

      revision.update!(
        status: "rejected",
        reviewed_at: Time.current,
        rejection_reason: attributes[:reason]
      )
      fallback = profile.approved_revision
      fallback ||= profile.revisions
        .where(profile_type: "external", status: %w[pending_review approved])
        .where.not(id: revision.id)
        .order(version: :desc)
        .first
      profile_attributes = {
        published_revision: fallback,
        profile_status: "published"
      }
      profile_attributes[:working_revision] = revision unless
        revision.external? && profile.working_revision&.self_service?
      profile.update!(profile_attributes)
    when "hidden"
      require_status!(revision.status, "approved")
      raise Conflict, "profile revision is not public" unless profile.published_revision_id == revision.id

      profile.update!(profile_status: "suspended")
    when "restored"
      raise Conflict, "profile revision is not hidden" unless profile.profile_status == "suspended" &&
        profile.published_revision_id == revision.id

      profile.update!(profile_status: "published")
    end
  end

  def transition_photo!(photo, attributes, public_keys_to_delete, created_public_keys)
    profile = photo.professional_profile.lock!
    case attributes[:action]
    when "approved"
      require_status!(photo.status, "pending_review")
      raise Conflict, "profile photo is not current" unless current_photo_id(profile) == photo.id

      public_key = publisher.publish(target: photo, target_type: "profile_photo")
      created_public_keys << public_key
      previous = profile.approved_photo
      if previous && previous != photo
        public_keys_to_delete << previous.public_key
        previous.update!(status: "superseded", public_key: nil)
      end
      photo.update!(status: "approved", public_key:, reviewed_at: Time.current, rejection_reason: nil)
      profile.update!(approved_photo: photo, working_photo: photo)
    when "rejected"
      require_status!(photo.status, "pending_review")
      raise Conflict, "profile photo is not current" unless current_photo_id(profile) == photo.id

      photo.update!(status: "rejected", reviewed_at: Time.current, rejection_reason: attributes[:reason])
      profile.update!(published_photo: profile.approved_photo) if profile.profile_status == "published"
    when "hidden"
      require_status!(photo.status, "approved")
      raise Conflict, "profile photo is not current" unless profile.published_photo_id == photo.id

      public_keys_to_delete << photo.public_key
      photo.update!(status: "hidden", public_key: nil, hidden_at: Time.current)
      if profile.published_photo_id == photo.id
        profile.update!(published_photo: nil, approved_photo: nil)
      end
    when "restored"
      require_status!(photo.status, "hidden")
      public_key = publisher.publish(target: photo, target_type: "profile_photo")
      created_public_keys << public_key
      photo.update!(status: "approved", public_key:, hidden_at: nil)
      profile.update!(published_photo: photo, approved_photo: photo)
    end
  end

  def transition_portfolio!(item, attributes, public_keys_to_delete, created_public_keys)
    raise ActiveRecord::RecordNotFound if item.deleted_at

    case attributes[:action]
    when "approved"
      require_status!(item.status, "pending_review")
      item.update!(status: "approved", reviewed_at: Time.current, rejection_reason: nil)
    when "rejected"
      require_status!(item.status, "pending_review")
      public_keys_to_delete << item.public_key if item.public_key.present?
      item.update!(
        status: "rejected",
        public_key: nil,
        reviewed_at: Time.current,
        rejection_reason: attributes[:reason]
      )
    when "hidden"
      require_status!(item.status, "approved")
      public_keys_to_delete << item.public_key if item.public_key.present?
      item.update!(status: "hidden", public_key: nil, hidden_at: Time.current)
    when "restored"
      require_status!(item.status, "hidden")
      public_key = publisher.publish(target: item, target_type: "portfolio_item")
      created_public_keys << public_key
      item.update!(status: "approved", public_key:, hidden_at: nil)
    end
  end

  def transition_verification!(request_record, attributes)
    require_status!(request_record.status, "pending_review")
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
    else
      raise Conflict, "verification decision is not allowed"
    end
  end

  def require_status!(actual, expected)
    raise Conflict, "moderation target changed" unless actual == expected
  end

  def current_photo_id(profile)
    (profile.profile_status == "published") ? profile.published_photo_id : profile.working_photo_id
  end

  def cleanup_created_public_keys(public_keys)
    public_keys.each { |public_key| publisher.delete(public_key) }
  rescue => error
    Rails.error.report(error)
    Rails.logger.error("moderation_public_media_cleanup_failed class=#{error.class}")
  end
end

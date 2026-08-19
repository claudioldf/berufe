# frozen_string_literal: true

class ModerationQueueSummaryQuery
  def call(now: Time.current)
    pending_times = [
      ProfessionalProfileRevision.where(status: "pending_review").minimum(:submitted_at),
      ProfessionalProfilePhoto.where(status: "pending_review").minimum(:submitted_at),
      PortfolioItem.active.where(status: "pending_review").minimum(:submitted_at),
      VerificationRequest.where(status: "pending_review").minimum(:submitted_at),
      unreviewed_relationships.minimum(:responded_at)
    ].compact
    {
      pending_count: pending_count,
      reviewed_today_count: ModerationAction.where(
        action: %w[approved rejected],
        created_at: now.all_day
      ).count,
      oldest_pending_submitted_at: pending_times.min
    }
  end

  private

  def pending_count
    ProfessionalProfileRevision.where(status: "pending_review").count +
      ProfessionalProfilePhoto.where(status: "pending_review").count +
      PortfolioItem.active.where(status: "pending_review").count +
      VerificationRequest.where(status: "pending_review").count +
      unreviewed_relationships.count
  end

  def unreviewed_relationships
    reviewed_ids = ModerationAction
      .where(target_type: "professional_relationship")
      .select(:target_id)
    ProfessionalRelationship.where(status: "accepted").where.not(id: reviewed_ids)
  end
end

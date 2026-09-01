# frozen_string_literal: true

class ModerationQueueSummaryQuery
  def call(now: Time.current)
    oldest_pending = VerificationRequest.where(status: "pending_review").minimum(:submitted_at)
    {
      pending_count: pending_count,
      reviewed_today_count: ModerationAction.where(
        target_type: "verification_request",
        action: %w[approved rejected],
        created_at: now.all_day
      ).count,
      oldest_pending_submitted_at: oldest_pending
    }
  end

  private

  def pending_count
    VerificationRequest.where(status: "pending_review").count
  end
end

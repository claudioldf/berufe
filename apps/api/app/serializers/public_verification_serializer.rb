# frozen_string_literal: true

class PublicVerificationSerializer
  def initialize(profile)
    @profile = profile
  end

  def as_json(*)
    approved_identity = profile.verification_requests
      .identity
      .where(status: "approved", public_label: ModerationDecision::IDENTITY_LABEL)
      .where.not(verified_at: nil)
      .order(verified_at: :desc, id: :desc)
      .first

    {
      phone_confirmed: true,
      identity: approved_identity && {
        label: approved_identity.public_label,
        verified_at: approved_identity.verified_at.iso8601
      }
    }
  end

  private

  attr_reader :profile
end

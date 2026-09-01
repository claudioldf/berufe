# frozen_string_literal: true

class ModerationTargetResolver
  def call(target_type:, target_id:)
    raise ActiveRecord::RecordNotFound, "moderation target" unless target_type.to_s == "verification_request"

    VerificationRequest.find(target_id)
  end
end

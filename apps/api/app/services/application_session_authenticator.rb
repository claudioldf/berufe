# frozen_string_literal: true

class ApplicationSessionAuthenticator
  def call(token:, now: Time.current)
    return if token.blank?

    token_digest = ApplicationSession.digest_token(token)
    ApplicationSession.transaction do
      application_session = ApplicationSession.includes(:user_account, impersonated_user_account: :professional_profile)
        .lock.find_by(token_digest:)
      next unless application_session&.active?(now:)

      unless application_session.user_account.active?
        application_session.user_account.revoke_all_sessions!(now:)
        next
      end

      if application_session.impersonating? && !application_session.impersonation_target_eligible?
        application_session.update_column(:impersonated_user_account_id, nil)
        application_session.association(:impersonated_user_account).reset
      end

      application_session.record_activity!(now:)
      application_session
    end
  end
end

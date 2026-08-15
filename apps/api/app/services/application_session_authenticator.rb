# frozen_string_literal: true

class ApplicationSessionAuthenticator
  def call(token:, now: Time.current)
    return if token.blank?

    token_digest = ApplicationSession.digest_token(token)
    ApplicationSession.transaction do
      application_session = ApplicationSession.includes(:user_account).lock.find_by(token_digest:)
      next unless application_session&.active?(now:)

      unless application_session.user_account.active?
        application_session.user_account.revoke_all_sessions!(now:)
        next
      end

      application_session.record_activity!(now:)
      application_session
    end
  end
end

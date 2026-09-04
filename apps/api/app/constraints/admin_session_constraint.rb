# frozen_string_literal: true

class AdminSessionConstraint
  SESSION_ENV_KEY = "berufe.current_application_session"

  def matches?(request)
    session = ApplicationSessionAuthenticator.new.call(
      token: request.cookies[ApplicationSession::COOKIE_NAME]
    )
    return false unless session&.user_account&.admin?
    return false unless session.authentication_method == "password"
    return false if session.impersonating?

    request.env[SESSION_ENV_KEY] = session
    true
  rescue ActiveRecord::ActiveRecordError => error
    Rails.error.report(error)
    false
  end
end

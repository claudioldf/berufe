# frozen_string_literal: true

class AdminMfaConstraint
  SESSION_ENV_KEY = "berufe.current_application_session"

  def matches?(request)
    session = request.env[SESSION_ENV_KEY]

    session&.active? && session.admin? && session.mfa_current?
  end
end

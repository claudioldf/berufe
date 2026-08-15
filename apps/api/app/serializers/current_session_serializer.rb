# frozen_string_literal: true

class CurrentSessionSerializer
  def initialize(application_session:, csrf_token:)
    @application_session = application_session
    @account = application_session.user_account
    @csrf_token = csrf_token
  end

  def as_json(*)
    {
      account: {
        id: @account.id,
        role: @account.role,
        status: @account.status
      },
      session: {
        authentication_method: @application_session.authentication_method,
        authenticated_at: @application_session.authenticated_at,
        mfa_authenticated: @application_session.mfa_authenticated_at.present?,
        idle_expires_at: @application_session.idle_expires_at,
        absolute_expires_at: @application_session.absolute_expires_at
      },
      csrf_token: @csrf_token
    }
  end
end

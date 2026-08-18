# frozen_string_literal: true

class CurrentSessionSerializer
  def initialize(application_session:)
    @application_session = application_session
    @account = application_session.user_account
  end

  def as_json(*)
    {
      account: {
        id: @account.id,
        role: @account.role,
        status: @account.status,
        registration_completed: @account.registration_completed?,
        professional_profile_id: professional_profile&.id,
        relationship_eligible: relationship_eligible?
      },
      session: {
        authentication_method: @application_session.authentication_method,
        authenticated_at: @application_session.authenticated_at,
        idle_expires_at: @application_session.idle_expires_at,
        absolute_expires_at: @application_session.absolute_expires_at
      }
    }
  end

  private

  def professional_profile
    @professional_profile ||= @account.professional_profile
  end

  def relationship_eligible?
    return false unless @account.professional? && professional_profile

    professional_profile.verification_requests.identity.exists?(status: "approved")
  end
end

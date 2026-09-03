# frozen_string_literal: true

class CurrentSessionSerializer
  def initialize(application_session:)
    @application_session = application_session
    @account = application_session.effective_user_account
  end

  def as_json(*)
    {
      account: {
        id: @account.id,
        role: @account.role,
        status: @account.status,
        registered: @account.registered?,
        verified: @account.phone_verified?,
        registration_completed: @account.registration_completed?,
        onboarding_completed: onboarding_completed?,
        registration_display_name: professional_profile&.working_revision&.display_name,
        professional_profile_id: professional_profile&.id,
        relationship_eligible: relationship_eligible?
      },
      session: {
        authentication_method: @application_session.authentication_method,
        impersonating: @application_session.impersonating?,
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

  def onboarding_completed?
    professional_profile&.has_self_service_publication? == true
  end

  def relationship_eligible?
    return false unless @account.registered? && @account.phone_verified? && professional_profile

    professional_profile.verification_requests.identity.exists?(status: "approved")
  end
end

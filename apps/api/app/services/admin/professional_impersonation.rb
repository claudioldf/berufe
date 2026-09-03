# frozen_string_literal: true

module Admin
  class ProfessionalImpersonation
    class Unavailable < StandardError; end

    def start!(application_session:, professional_account_id:)
      application_session.with_lock do
        raise Unavailable if application_session.impersonating?

        target = UserAccount.includes(:professional_profile).lock.find_by!(
          id: professional_account_id,
          role: "professional"
        )
        raise Unavailable unless eligible?(target)

        application_session.update!(impersonated_user_account: target)
      end

      application_session
    end

    def stop!(application_session:)
      application_session.with_lock do
        application_session.update!(impersonated_user_account: nil) if application_session.impersonating?
      end

      application_session
    end

    private

    def eligible?(target)
      target.active? && target.phone_verified? && target.registration_completed?
    end
  end
end

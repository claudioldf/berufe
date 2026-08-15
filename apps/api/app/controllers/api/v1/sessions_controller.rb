# frozen_string_literal: true

module Api
  module V1
    class SessionsController < BaseController
      before_action :prevent_caching
      before_action :authenticate_application_session!

      rescue_from ActiveRecord::ActiveRecordError do
        render_api_error(
          code: "session_unavailable",
          message: "Não foi possível consultar sua sessão agora.",
          status: :service_unavailable
        )
      end

      def show
        csrf_token = Current.application_session.rotate_csrf_token!
        return render_authentication_required unless csrf_token

        render json: {
          data: {
            account: account_summary,
            session: session_summary,
            csrf_token:
          },
          request_id: Current.request_id
        }
      end

      def destroy
        Current.application_session.revoke!
        clear_application_session_cookie
        head :no_content
      end

      private

      def account_summary
        {
          id: Current.user_account.id,
          role: Current.user_account.role,
          status: Current.user_account.status
        }
      end

      def session_summary
        application_session = Current.application_session
        {
          authentication_method: application_session.authentication_method,
          authenticated_at: application_session.authenticated_at,
          mfa_authenticated: application_session.mfa_authenticated_at.present?,
          idle_expires_at: application_session.idle_expires_at,
          absolute_expires_at: application_session.absolute_expires_at
        }
      end
    end
  end
end

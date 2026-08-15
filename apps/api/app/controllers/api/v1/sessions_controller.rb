# frozen_string_literal: true

module Api
  module V1
    class SessionsController < BaseController
      before_action :prevent_caching
      before_action :authenticate_application_session!
      before_action :verify_csrf_and_origin!, only: :destroy

      rescue_from ActiveRecord::ActiveRecordError do
        render_api_error(
          code: "session_unavailable",
          message: "Não foi possível consultar sua sessão agora.",
          status: :service_unavailable
        )
      end

      def show
        authorize Current.application_session
        csrf_token = Current.application_session.rotate_csrf_token!
        return render_authentication_required unless csrf_token

        render json: {
          data: CurrentSessionSerializer.new(
            application_session: Current.application_session,
            csrf_token:
          ),
          request_id: Current.request_id
        }
      end

      def destroy
        authorize Current.application_session
        Current.application_session.revoke!
        clear_application_session_cookie
        head :no_content
      end
    end
  end
end

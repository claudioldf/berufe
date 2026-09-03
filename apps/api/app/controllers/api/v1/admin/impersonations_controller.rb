# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ImpersonationsController < BaseController
        before_action :prevent_caching
        before_action :authenticate_password_admin_actor_session!

        def create
          session = impersonation.start!(
            application_session: Current.application_session,
            professional_account_id: params.require(:professional_account_id)
          )
          render_session(session)
        rescue ::Admin::ProfessionalImpersonation::Unavailable
          render_unavailable
        end

        def destroy
          session = impersonation.stop!(application_session: Current.application_session)
          render_session(session)
        end

        private

        def impersonation
          @impersonation ||= ::Admin::ProfessionalImpersonation.new
        end

        def render_session(session)
          render json: {
            data: CurrentSessionSerializer.new(application_session: session),
            request_id: Current.request_id
          }
        end

        def render_unavailable
          render_api_error(
            code: "impersonation_unavailable",
            message: "Não é possível gerenciar esta conta profissional.",
            status: :conflict
          )
        end
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    module Professional
      class DataErasureRequestsController < BaseController
        CONFIRMATION = "EXCLUIR"

        before_action :prevent_caching
        before_action :authenticate_application_session!

        def create
          account = Current.user_account
          authorize account, :request_data_erasure?
          validate_confirmation!
          return if performed?

          request_record = ProfessionalDataErasureRequester.new.call(
            phone_e164: account.phone_e164,
            ticket_reference: "SELF-#{Current.request_id}".first(100),
            verification_session: Current.application_session,
            request_source: "self_service",
            confirmation_version: DataErasureRequest::SELF_SERVICE_CONFIRMATION_VERSION,
            issue_status_token: true
          )
          clear_application_session_cookie
          render json: {
            data: {
              status_token: request_record.status_token,
              request: DataErasureRequestSerializer.new(request_record)
            },
            request_id: Current.request_id
          }, status: :accepted
        rescue ProfessionalDataErasureRequester::VerificationRequired
          render_api_error(
            code: "recent_verification_required",
            message: "Confirme seu telefone por SMS novamente para continuar.",
            status: :precondition_required
          )
        rescue ActiveRecord::ActiveRecordError => error
          report_service_error(error)
          render_api_error(
            code: "erasure_request_unavailable",
            message: "Não foi possível registrar a solicitação agora.",
            status: :service_unavailable
          )
        end

        private

        def validate_confirmation!
          return if params.require(:confirmation) == CONFIRMATION

          render_api_error(
            code: "confirmation_required",
            message: "Digite EXCLUIR para confirmar a exclusão irreversível.",
            status: :unprocessable_entity,
            field_errors: {confirmation: ["deve ser EXCLUIR"]}
          )
        end
      end
    end
  end
end

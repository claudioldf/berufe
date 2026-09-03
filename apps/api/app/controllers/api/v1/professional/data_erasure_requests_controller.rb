# frozen_string_literal: true

module Api
  module V1
    module Professional
      class DataErasureRequestsController < BaseController
        before_action :prevent_caching
        before_action :authenticate_application_session!
        before_action :reject_impersonated_action!

        def create
          account = Current.user_account
          authorize account, :request_data_erasure?

          request_record = ProfessionalDataErasureRequester.new.call(
            phone_e164: account.phone_e164,
            ticket_reference: "SELF-#{Current.request_id}".first(100),
            require_recent_verification: false,
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
        rescue ActiveRecord::ActiveRecordError => error
          report_service_error(error)
          render_api_error(
            code: "erasure_request_unavailable",
            message: "Não foi possível registrar a solicitação agora.",
            status: :service_unavailable
          )
        end
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    class ProfessionalRegistrationsController < BaseController
      before_action :prevent_caching
      before_action :authenticate_application_session!
      def update
        authorize Current.user_account, :complete_registration?
        profile = ProfessionalRegistration.new.call(
          user_account: Current.user_account,
          display_name: params[:display_name],
          accepted: params[:accepted]
        )

        render json: {
          data: ProfessionalRegistrationSerializer.new(profile),
          request_id: Current.request_id
        }
      rescue ProfessionalRegistration::Invalid => error
        render_api_error(
          code: "validation_failed",
          message: "Revise os campos informados.",
          status: :unprocessable_entity,
          field_errors: error.field_errors
        )
      rescue ActiveRecord::ActiveRecordError => error
        report_service_error(error)
        render_api_error(
          code: "registration_unavailable",
          message: "Não foi possível concluir seu cadastro agora.",
          status: :service_unavailable
        )
      end
    end
  end
end

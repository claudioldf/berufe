# frozen_string_literal: true

module Api
  module V1
    module Professional
      class VerificationRequestsController < BaseController
        before_action :prevent_caching
        before_action :authenticate_application_session!
        before_action :reject_impersonated_action!

        def create
          profile = Current.user_account.professional_profile
          raise ActiveRecord::RecordNotFound unless profile

          authorize profile, :update?
          request_record = VerificationRequestCreator.new.call(
            profile:,
            media_upload_id: verification_request_params.fetch(:media_upload_id),
            verification_type: verification_request_params.fetch(:verification_type)
          )
          render json: {
            data: ProfessionalWorkspaceSerializer.new(profile.reload),
            request_id: Current.request_id
          }, status: :created,
            location: "/api/v1/professional/verification-requests/#{request_record.id}"
        rescue VerificationRequestCreator::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "A evidência não está pronta para envio.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        end

        private

        def verification_request_params
          params.require(:verification_request).permit(
            :media_upload_id,
            :verification_type
          ).to_h.symbolize_keys
        end
      end
    end
  end
end

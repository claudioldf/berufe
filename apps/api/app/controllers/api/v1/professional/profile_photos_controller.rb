# frozen_string_literal: true

module Api
  module V1
    module Professional
      class ProfilePhotosController < BaseController
        before_action :prevent_caching
        before_action :authenticate_application_session!

        def update
          profile = Current.user_account.professional_profile
          raise ActiveRecord::RecordNotFound unless profile

          authorize profile, :update?
          ProfessionalProfilePhotoAttacher.new.call(
            profile:,
            media_upload_id: params.require(:media_upload_id)
          )
          render json: {
            data: ProfessionalWorkspaceSerializer.new(profile.reload),
            request_id: Current.request_id
          }
        rescue ProfessionalProfilePhotoAttacher::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "A foto não está pronta para envio.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        end
      end
    end
  end
end

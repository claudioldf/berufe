# frozen_string_literal: true

module Api
  module V1
    module Professional
      class ProfilePhotosController < BaseController
        before_action :prevent_caching
        before_action :authenticate_application_session!

        def update
          profile = owned_profile!
          ProfessionalProfilePhotoAttacher.new.call(
            profile:,
            media_upload_id: params.require(:media_upload_id)
          )
          render json: workspace_response(profile)
        rescue ProfessionalProfilePhotoAttacher::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "A foto não está pronta para envio.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        end

        def destroy
          profile = owned_profile!
          ProfessionalProfilePhotoRemover.new.call(profile:)
          render json: workspace_response(profile)
        end

        private

        def owned_profile!
          profile = Current.user_account.professional_profile
          raise ActiveRecord::RecordNotFound unless profile

          authorize profile, :update?
          profile
        end

        def workspace_response(profile)
          {
            data: ProfessionalWorkspaceSerializer.new(profile.reload),
            request_id: Current.request_id
          }
        end
      end
    end
  end
end

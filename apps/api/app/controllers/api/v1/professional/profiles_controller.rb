# frozen_string_literal: true

module Api
  module V1
    module Professional
      class ProfilesController < BaseController
        before_action :prevent_caching
        before_action :authenticate_application_session!

        def update
          profile = Current.user_account.professional_profile
          raise ActiveRecord::RecordNotFound unless profile

          authorize profile, :update?
          ProfessionalProfile.transaction do
            if params[:identity].present?
              ProfessionalProfileIdentityUpdater.new.call(
                profile:,
                attributes: identity_params.to_h.symbolize_keys
              )
            end
            if params[:services].present? || params[:coverage].present?
              ProfessionalProfileSupplyUpdater.new.call(
                profile:,
                services: supply_params.require(:services),
                coverage: supply_params.require(:coverage)
              )
            end
          end
          render json: {
            data: ProfessionalWorkspaceSerializer.new(profile.reload),
            request_id: Current.request_id
          }
        rescue ProfessionalProfileIdentityUpdater::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "Revise os campos informados.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        rescue ProfessionalProfileSupplyUpdater::Invalid => error
          render_api_error(
            code: "validation_failed",
            message: "Revise os serviços e a área de atendimento.",
            status: :unprocessable_entity,
            field_errors: error.field_errors
          )
        end

        private

        def identity_params
          params.require(:identity).permit(
            :display_name,
            :headline,
            :bio,
            :years_experience,
            :whatsapp,
            :instagram,
            :youtube
          )
        end

        def supply_params
          params.permit(
            services: %i[service_id is_primary note],
            coverage: [:all_joinville, {neighborhood_codes: []}]
          )
        end
      end
    end
  end
end

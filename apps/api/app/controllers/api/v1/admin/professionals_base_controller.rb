# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ProfessionalsBaseController < BaseController
        before_action :prevent_caching
        before_action :authenticate_password_admin_session!
        before_action :authorize_professional_directory!

        private

        def authorize_professional_directory!
          authorize :admin_professional, :manage?
        end

        def directory_query_params
          {
            page: params[:page],
            per_page: params[:per_page],
            q: params[:q],
            phone: params[:phone],
            city: params[:city],
            state: params[:state],
            identity_verified: params[:identity_verified],
            onboarding_finished: params[:onboarding_finished],
            sort: params[:sort]
          }
        end
      end
    end
  end
end

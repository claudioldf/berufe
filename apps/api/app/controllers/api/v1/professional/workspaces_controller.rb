# frozen_string_literal: true

module Api
  module V1
    module Professional
      class WorkspacesController < BaseController
        before_action :prevent_caching
        before_action :authenticate_application_session!

        def show
          profile = Current.user_account.professional_profile
          raise ActiveRecord::RecordNotFound unless profile

          authorize profile, :show?
          render json: {
            data: ProfessionalWorkspaceSerializer.new(profile),
            request_id: Current.request_id
          }
        end
      end
    end
  end
end

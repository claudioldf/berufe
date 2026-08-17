# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ModerationBaseController < BaseController
        before_action :prevent_caching
        before_action :authenticate_password_admin_session!
        before_action :authorize_moderation!

        private

        def authorize_moderation!
          authorize :moderation, :manage?
        end
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    module Professional
      class PortfolioItemImagesController < BaseController
        before_action :prevent_caching
        before_action :authenticate_application_session!

        def show
          profile = owned_profile!
          item = profile.portfolio_items.active.find(params[:id])
          body = MediaStorage.build.read(scope: :private, key: item.private_key)
          extension = (item.content_type == "image/png") ? "png" : "jpg"
          response.set_header("X-Content-Type-Options", "nosniff")
          send_data(
            body,
            type: item.content_type,
            disposition: "inline",
            filename: "berufe-portfolio-#{item.id}.#{extension}"
          )
        rescue Errno::ENOENT, Aws::S3::Errors::NoSuchKey
          raise ActiveRecord::RecordNotFound
        end

        private

        def owned_profile!
          profile = Current.user_account.professional_profile
          raise ActiveRecord::RecordNotFound unless profile

          authorize profile, :update?
          profile
        end
      end
    end
  end
end

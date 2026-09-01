# frozen_string_literal: true

module Api
  module V1
    module Professional
      class ProfilePhotoImagesController < BaseController
        before_action :prevent_caching
        before_action :authenticate_application_session!

        def show
          profile = owned_profile!
          photo = profile.profile_photos.active.find(params[:id])
          raise ActiveRecord::RecordNotFound unless profile.profile_photo_id == photo.id

          body = MediaStorage.build.read(scope: :private, key: photo.private_key)
          response.set_header("X-Content-Type-Options", "nosniff")
          send_data(
            body,
            type: photo.content_type,
            disposition: "inline",
            filename: "berufe-profile-photo-#{photo.id}.jpg"
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

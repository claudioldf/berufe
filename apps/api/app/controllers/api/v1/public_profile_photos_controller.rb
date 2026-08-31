# frozen_string_literal: true

module Api
  module V1
    class PublicProfilePhotosController < BaseController
      def show
        photo = ProfessionalProfilePhoto.publicly_visible.find(params[:id])
        body = MediaStorage.build.read(scope: :private, key: photo.private_key)
        send_data(
          body,
          type: photo.content_type,
          disposition: "inline",
          filename: "berufe-profile-photo-#{photo.id}.jpg"
        )
        response.set_header("Cache-Control", "public, max-age=0, must-revalidate")
        response.set_header("X-Content-Type-Options", "nosniff")
      rescue Errno::ENOENT, Aws::S3::Errors::NoSuchKey
        raise ActiveRecord::RecordNotFound
      end
    end
  end
end

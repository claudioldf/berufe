# frozen_string_literal: true

module Api
  module V1
    class PublicProfilePhotosController < BaseController
      def show
        photo = ProfessionalProfilePhoto.publicly_visible.find(params[:id])
        scope, key = (photo.approved? && photo.public_key.present?) ? [:public, photo.public_key] : [:private, photo.private_key]
        body = MediaStorage.build.read(scope:, key:)
        send_data(
          body,
          type: photo.content_type,
          disposition: "inline",
          filename: "berufe-profile-photo-#{photo.id}.jpg"
        )
        cache_control = photo.pending_review? ? "no-store" : "public, max-age=0, must-revalidate"
        response.set_header("Cache-Control", cache_control)
        response.set_header("X-Content-Type-Options", "nosniff")
      rescue Errno::ENOENT, Aws::S3::Errors::NoSuchKey
        raise ActiveRecord::RecordNotFound
      end
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    class PublicProfilePhotosController < BaseController
      # s-maxage applies to the shared cache (Cloudflare) only, so the edge may
      # hold an image for five minutes while browsers still revalidate on every
      # request -- and that revalidation is answered by the edge instead of
      # reaching Rails and re-reading the whole object from R2. Five minutes is
      # also the ceiling on how long a taken-down profile's image stays
      # reachable; see docs/PRODUCTION_DEPLOYMENT.md.
      # Rack reorders Cache-Control directives on the way out; this literal
      # matches what actually ships so the source reads the same as the wire.
      SHARED_CACHE_CONTROL = "max-age=0, public, must-revalidate, s-maxage=300"

      def show
        photo = ProfessionalProfilePhoto.publicly_visible.find(params[:id])
        body = MediaStorage.build.read(scope: :private, key: photo.private_key)
        send_data(
          body,
          type: photo.content_type,
          disposition: "inline",
          filename: "berufe-profile-photo-#{photo.id}.jpg"
        )
        response.set_header("Cache-Control", SHARED_CACHE_CONTROL)
        response.set_header("X-Content-Type-Options", "nosniff")
      rescue Errno::ENOENT, Aws::S3::Errors::NoSuchKey
        raise ActiveRecord::RecordNotFound
      end
    end
  end
end

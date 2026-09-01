# frozen_string_literal: true

module Api
  module V1
    class PublicPortfolioImagesController < BaseController
      def show
        item = PortfolioItem
          .publicly_visible
          .joins(:professional_profile)
          .merge(ProfessionalProfile.publicly_eligible)
          .find(params[:id])
        body = MediaStorage.build.read(scope: :private, key: item.private_key)
        extension = (item.content_type == "image/png") ? "png" : "jpg"
        send_data(
          body,
          type: item.content_type,
          disposition: "inline",
          filename: "berufe-portfolio-#{item.id}.#{extension}"
        )
        response.set_header("Cache-Control", "public, max-age=0, must-revalidate")
        response.set_header("X-Content-Type-Options", "nosniff")
      rescue Errno::ENOENT, Aws::S3::Errors::NoSuchKey
        raise ActiveRecord::RecordNotFound
      end
    end
  end
end

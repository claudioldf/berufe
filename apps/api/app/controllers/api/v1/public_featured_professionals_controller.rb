# frozen_string_literal: true

module Api
  module V1
    class PublicFeaturedProfessionalsController < BaseController
      def index
        professionals = FeaturedPublicProfessionalsQuery.new.call

        render json: {
          data: {
            professionals: professionals.map { |profile| PublicProfessionalCardSerializer.new(profile).as_json }
          },
          request_id: Current.request_id
        }
      rescue ActiveRecord::ActiveRecordError
        render_api_error(
          code: "service_unavailable",
          message: "Profissionais temporariamente indisponíveis.",
          status: :service_unavailable
        )
      end
    end
  end
end

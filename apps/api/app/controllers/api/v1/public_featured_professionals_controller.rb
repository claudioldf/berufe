# frozen_string_literal: true

module Api
  module V1
    class PublicFeaturedProfessionalsController < BaseController
      def index
        professionals = FeaturedPublicProfessionalsQuery.new.call(city_code: params[:city_code])

        render json: {
          data: {
            professionals: professionals.map { |profile| PublicProfessionalCardSerializer.new(profile).as_json }
          },
          request_id: Current.request_id
        }
      rescue ActiveRecord::ActiveRecordError => error
        report_service_error(error)
        render_api_error(
          code: "service_unavailable",
          message: "Profissionais temporariamente indisponíveis.",
          status: :service_unavailable
        )
      end
    end
  end
end

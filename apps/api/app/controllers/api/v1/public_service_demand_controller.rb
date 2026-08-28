# frozen_string_literal: true

module Api
  module V1
    class PublicServiceDemandController < BaseController
      # Public reads stay cacheable on purpose (see PublicProfessionalsController).
      SHARED_CACHE_CONTROL = "max-age=0, public, must-revalidate"

      after_action :allow_shared_cache, only: :show

      def show
        service = Service.publicly_active.find_by(slug: params[:service_slug])
        raise ActiveRecord::RecordNotFound unless service

        location = SupportedSearchLocations.new.find_by_route(
          state_slug: params[:state_slug],
          city_slug: params[:city_slug]
        )
        raise ActiveRecord::RecordNotFound unless location

        result = PublicServiceDemand.new.call(service_id: service.id, city_code: location.city_code)
        render json: {
          data: {
            released: result.released,
            searches: result.released ? result.searches : nil
          },
          request_id: Current.request_id
        }
      rescue ActiveRecord::RecordNotFound
        raise
      rescue ActiveRecord::ActiveRecordError => error
        report_service_error(error)
        render_api_error(
          code: "service_unavailable",
          message: "A demanda está temporariamente indisponível.",
          status: :service_unavailable
        )
      end

      private

      def allow_shared_cache
        return unless response.successful?

        response.set_header("Cache-Control", SHARED_CACHE_CONTROL)
      end
    end
  end
end

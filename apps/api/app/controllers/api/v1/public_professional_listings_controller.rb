# frozen_string_literal: true

module Api
  module V1
    class PublicProfessionalListingsController < BaseController
      # Public reads stay cacheable on purpose (see PublicProfessionalsController).
      SHARED_CACHE_CONTROL = "max-age=0, public, must-revalidate"

      after_action :allow_shared_cache, only: :index

      def index
        service = Service.publicly_active.find_by(slug: params[:service_slug])
        raise ActiveRecord::RecordNotFound unless service

        location = SupportedSearchLocations.new.find_by_route(
          state_slug: params[:state_slug],
          city_slug: params[:city_slug]
        )
        raise ActiveRecord::RecordNotFound unless location

        page, per_page = PublicProfessionalSearch.normalize_pagination(
          page: params[:page],
          per_page: params[:per_page]
        )
        result = fetch_result(service:, location:, page:, per_page:)

        render json: {
          data: PublicProfessionalListingSerializer.new(result, service:, location:).as_json,
          request_id: Current.request_id
        }
      rescue ActiveRecord::RecordNotFound
        raise
      rescue ActiveRecord::ActiveRecordError => error
        report_service_error(error)
        render_api_error(
          code: "service_unavailable",
          message: "A listagem está temporariamente indisponível.",
          status: :service_unavailable
        )
      end

      private

      # A service/city combination can be a legitimate route with zero
      # current supply -- that is a recruitment opportunity ("be the first
      # electrician in Blumenau"), not an error. Service and location have
      # already been validated above, so any InvalidInput here can only be
      # PublicProfessionalSearch's own supply-availability check.
      def fetch_result(service:, location:, page:, per_page:)
        PublicProfessionalSearch.new.call_with_filters(
          service_id: service.id,
          city_code: location.city_code,
          page:,
          per_page:
        )
      rescue PublicProfessionalSearch::InvalidInput
        PublicProfessionalSearch::Result.new(
          criteria: nil,
          services: [service],
          professionals: ProfessionalProfile.none,
          related_services: [],
          page:,
          per_page:,
          total_count: 0
        )
      end

      def allow_shared_cache
        return unless response.successful?

        response.set_header("Cache-Control", SHARED_CACHE_CONTROL)
      end
    end
  end
end

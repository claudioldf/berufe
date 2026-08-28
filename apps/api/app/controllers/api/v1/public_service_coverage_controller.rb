# frozen_string_literal: true

module Api
  module V1
    class PublicServiceCoverageController < BaseController
      # Public reads stay cacheable on purpose (see PublicProfessionalsController).
      SHARED_CACHE_CONTROL = "max-age=0, public, must-revalidate"

      after_action :allow_shared_cache, only: :index

      def index
        return render_entries([]) if unresolved_filter?

        entries = PublicServiceCoverageQuery.new.call(
          service_id: filter_service&.id,
          city_code: filter_location&.city_code
        )
        render_entries(entries)
      rescue ActiveRecord::ActiveRecordError => error
        report_service_error(error)
        render_api_error(
          code: "service_unavailable",
          message: "A cobertura está temporariamente indisponível.",
          status: :service_unavailable
        )
      end

      private

      def render_entries(entries)
        render json: {
          data: {entries: entries.map { |entry| PublicServiceCoverageSerializer.new(entry).as_json }},
          request_id: Current.request_id
        }
      end

      # A filter that was supplied but does not resolve to anything real
      # (an unknown slug) has no matches by definition -- these are query
      # filters, not path-identified resources, so that is an empty result,
      # not a 404.
      def unresolved_filter?
        (params[:service_slug].present? && filter_service.nil?) ||
          (params[:city_slug].present? && filter_location.nil?)
      end

      def filter_service
        return @filter_service if defined?(@filter_service)

        @filter_service = params[:service_slug].present? ? Service.publicly_active.find_by(slug: params[:service_slug]) : nil
      end

      def filter_location
        return @filter_location if defined?(@filter_location)

        @filter_location = if params[:city_slug].present?
          SupportedSearchLocations.new.find_by_route(state_slug: params[:state_slug], city_slug: params[:city_slug])
        end
      end

      def allow_shared_cache
        return unless response.successful?

        response.set_header("Cache-Control", SHARED_CACHE_CONTROL)
      end
    end
  end
end

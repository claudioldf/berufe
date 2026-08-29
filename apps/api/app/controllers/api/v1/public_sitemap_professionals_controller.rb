# frozen_string_literal: true

module Api
  module V1
    class PublicSitemapProfessionalsController < BaseController
      SHARED_CACHE_CONTROL = "max-age=0, public, must-revalidate"

      after_action :allow_shared_cache, only: :index

      def index
        entries = PublicSitemapProfessionalsQuery.new.call
        render json: {
          data: {
            professionals: entries.map { |entry| {slug: entry.slug, updated_at: entry.updated_at&.iso8601} }
          },
          request_id: Current.request_id
        }
      rescue ActiveRecord::ActiveRecordError => error
        report_service_error(error)
        render_api_error(
          code: "service_unavailable",
          message: "A lista de perfis está temporariamente indisponível.",
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

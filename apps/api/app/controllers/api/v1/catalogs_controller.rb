# frozen_string_literal: true

module Api
  module V1
    class CatalogsController < BaseController
      def show
        categories = policy_scope(ServiceCategory)
        services = policy_scope(Service)
        render json: {
          data: PublicCatalogSerializer.new(categories:, services:),
          request_id: Current.request_id
        }
      rescue ActiveRecord::ActiveRecordError => error
        report_service_error(error)
        render_api_error(
          code: "service_unavailable",
          message: "Catálogo temporariamente indisponível.",
          status: :service_unavailable
        )
      end
    end
  end
end
